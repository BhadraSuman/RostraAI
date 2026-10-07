const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const { GoogleGenAI } = require("@google/genai");

admin.initializeApp();

/**
 * Dispatches targeted push notifications ONLY on Editor changes (Status, Note, Override).
 * Follower comments in subcollections never trigger FCM pushes.
 */
exports.onDayDocWritten = onDocumentWritten("pages/{pageId}/days/{date}", async (event) => {
  const pageId = event.params.pageId;
  const date = event.params.date;

  const afterData = event.data ? event.data.after.data() : null;
  const beforeData = event.data ? event.data.before.data() : null;

  if (!afterData) return; // Document deleted

  // Check for day override changes
  if (afterData.dayOverride && (!beforeData || JSON.stringify(beforeData.dayOverride) !== JSON.stringify(afterData.dayOverride))) {
    const override = afterData.dayOverride;
    const title = override.isNoClasses ? "No Classes Today" : `Timetable Override: Follows ${override.followsWeekday}`;
    const body = override.note || "Check the live timetable for updated schedule.";

    await admin.messaging().send({
      topic: `class_${pageId}`,
      notification: { title, body },
      data: { pageId, date, type: "day_override" },
    });
    return;
  }

  // Check for status changes in classes
  const statusesAfter = afterData.statuses || {};
  const statusesBefore = beforeData ? (beforeData.statuses || {}) : {};

  for (const [entryId, statusObj] of Object.entries(statusesAfter)) {
    const prev = statusesBefore[entryId];
    if (!prev || JSON.stringify(prev) !== JSON.stringify(statusObj)) {
      // Status was changed by CR
      const subject = statusObj.subject || "Class";
      const time = statusObj.time || "";
      const statusType = statusObj.status || "updated";
      const note = statusObj.note ? ` (${statusObj.note})` : "";

      let changeDesc = statusType;
      if (statusType === "cancelled") changeDesc = "cancelled today";
      else if (statusType === "roomMoved" || statusType === "room_moved") changeDesc = `moved to ${statusObj.updatedRoom || "new room"}`;

      const title = `${subject} ${time} ${changeDesc}`.trim();
      const body = `Updated by ${statusObj.updatedByName || "CR"}${note}`;

      // Target affected group or whole class
      const targetTopic = statusObj.group && statusObj.group !== "All"
        ? `class_${pageId}_group_${statusObj.group}`
        : `class_${pageId}`;

      await admin.messaging().send({
        topic: targetTopic,
        notification: { title, body },
        data: { pageId, date, entryId, type: "class_status" },
      });
      break; // Send one concise push per batch
    }
  }
});

/**
 * Server-Side Google Gemini Vision Timetable Parser.
 * API key is kept securely on the server.
 */
exports.parseTimetableWithGemini = onCall({ timeoutSeconds: 120, memory: "1GiB" }, async (request) => {
  const { imageBase64, mimeType } = request.data;
  if (!imageBase64) {
    throw new HttpsError("invalid-argument", "Missing imageBase64 parameter.");
  }

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    throw new HttpsError("failed-precondition", "Gemini API key is not configured on server.");
  }

  const ai = new GoogleGenAI({ apiKey });

  const systemInstruction = `
You are an expert college timetable extraction engine.
Analyze the provided timetable image or document.
Extract all recurring weekly class entries into a valid JSON array matching this exact schema:
[
  {
    "day": "MONDAY | TUESDAY | WEDNESDAY | THURSDAY | FRIDAY | SATURDAY",
    "startTime": "HH:mm in 24-hr format (e.g. 09:00, 10:00, 14:30)",
    "endTime": "HH:mm in 24-hr format (e.g. 10:00, 11:00, 16:30)",
    "subject": "Full subject name (e.g. Operating Systems)",
    "room": "Room or lab number (e.g. TP-401, Lab 3)",
    "teacher": "Faculty or teacher name (e.g. Dr. A. Sharma)",
    "group": "Batch or group if specified (e.g. 'All', 'B1', 'B2', 'Elective 1')"
  }
]
Return ONLY raw JSON. No markdown backticks, no explanatory prose.
`;

  try {
    const response = await ai.models.generateContent({
      model: "gemini-2.0-flash",
      contents: [
        {
          role: "user",
          parts: [
            { text: systemInstruction },
            {
              inlineData: {
                mimeType: mimeType || "image/jpeg",
                data: imageBase64,
              },
            },
          ],
        },
      ],
    });

    const rawText = response.text.trim();
    // Sanitize any backticks if present
    const cleanedJson = rawText.replace(/^```json/i, "").replace(/^```/, "").replace(/```$/, "").trim();
    const parsedSlots = JSON.parse(cleanedJson);

    return {
      success: true,
      entriesCount: parsedSlots.length,
      entries: parsedSlots,
    };
  } catch (err) {
    console.error("Gemini parse error:", err);
    throw new HttpsError("internal", `Failed to parse timetable: ${err.message}`);
  }
});
