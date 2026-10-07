# RostraAI — UI Design Product Specification & Prompt Guide
**Version:** 1.0 (v0.3 Specification Aligned)  
**Target Platforms:** Android Mobile (Flutter Material 3), Mobile Web (Responsive Read-Only)  
**Design Persona:** College Students & Class Representatives (CRs)  

---

## 1. Executive Design Philosophy

RostraAI solves a specific, high-stress problem: **college timetable changes get lost in WhatsApp chats, costing students attendance and causing confusion.**

### Design Principles:
1. **The 2-Second Rule:** A student opening the app should know their current class, next class, and whether it was cancelled or moved within 2 seconds.
2. **Single-Tap CR Execution:** The Class Representative is a volunteer doing administrative work. Updating a class status and formatting a WhatsApp message must take fewer than 3 taps and under 10 seconds.
3. **High-Contrast Emotional Relief:** The Attendance Margin must provide immediate cognitive clarity: never show just ambiguous percentages like `74.8%`; always show actionable whole numbers like **"Can miss 2 more"** (Green) or **"Attend 4 in a row"** (Red).
4. **Zero-Account Friction:** Never demand sign-up or onboarding forms to view or follow a timetable. Sign-in is strictly deferred until a user wishes to comment.

---

## 2. Design Tokens & Visual System

### 2.1 Color Palette

| Token Name | Hex Code | Light Surface Tint | Text on Tint | Semantic Meaning |
| :--- | :--- | :--- | :--- | :--- |
| `primary-navy` | `#1E3A8A` | `#EFF6FF` | `#1E3A8A` | Primary brand, AppBars, active navigation |
| `accent-indigo` | `#4F46E5` | `#EEF2FF` | `#4338CA` | Interactive elements, active chips |
| `status-normal` | `#10B981` | `#ECFDF5` | `#065F46` | Class scheduled, attendance safe |
| `status-cancelled`| `#EF4444` | `#FEF2F2` | `#991B1B` | Class cancelled, attendance critical deficit |
| `status-moved` | `#F59E0B` | `#FFFBEB` | `#92400E` | Room changed or time shifted |
| `status-extra` | `#8B5CF6` | `#F5F3FF` | `#5B21B6` | Extra class scheduled |
| `whatsapp-green`| `#25D366` | `#E8F8EE` | `#128C7E` | WhatsApp export action button |
| `surface-bg` | `#F8FAFC` | `#FFFFFF` | `#0F172A` | Background slate light |
| `surface-card` | `#FFFFFF` | N/A | `#0F172A` | Card backgrounds with 1px border `#E2E8F0` |

### 2.2 Typography Hierarchy
* **Font Family:** `Inter`, `Plus Jakarta Sans`, or `SF Pro Display` for UI; `JetBrains Mono` or tabular numbers for times and margins.
* **Heading 1 (Screen Titles):** `22px` / Bold / `-0.5px` tracking.
* **Heading 2 (Card Subject Names):** `16px` / SemiBold / `-0.2px` tracking.
* **Body Text (Faculty, Room, Notes):** `13px` / Regular / `1.4` line-height.
* **Time Code (Pills):** `12px` / Bold / Tabular Numbers.
* **Status Badges:** `11px` / Bold / Uppercase tracking `+0.5px`.

### 2.3 Component Geometry & Spacing
* **Corner Radius:**
  * Status Badges & Pills: `6px` – `8px`
  * Action Buttons & Input Fields: `12px`
  * Schedule & Attendance Cards: `16px`
  * Modal Sheets: `24px` top radius
* **Card Elevation:** Elevation 0 with a `1px` crisp border: `border: 1px solid #E2E8F0`.

---

## 3. Screen-by-Screen UI Blueprint

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ 1. Age Gate & Onboarding   ──►  2. Today View (Live Feed)                   │
│                                    ├── Filter by Group (All, B1, B2)        │
│                                    ├── Attendance Quick Margin Banner       │
│                                    └── Day Override Notice                  │
│                                           │                                 │
│                                           ▼                                 │
│                                 3. CR Quick-Action Sheet                    │
│                                    ├── Status Selector (Cancel, Room, Time) │
│                                    ├── Optional Note Input                  │
│                                    └── "Save & Post to WhatsApp" Button     │
│                                                                             │
│ 4. Weekly Grid Editor      ──►  5. Attendance Margin     ──► 6. Public Web  │
│    (Mon-Sat Studio)                (100% On-Device)             (Read-Only) │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

### Screen 1: 18+ Onboarding & Instant Follow Gate
* **Purpose:** Satisfy DPDP guidelines and establish instant class follow without creating an account.
* **Layout Structure:**
  * **Top:** Rounded circular app icon (`72x72px`) in soft blue tint + "RostraAI" bold wordmark + Tagline *"Class changes before you reach the room"*.
  * **Center Card:** Clean elevated container with headline *"Before you begin"*:
    * Explanatory microcopy: *"To comply with student safety and digital data guidelines, please confirm your eligibility."*
    * Checkbox 1: `[✓] I confirm I am 18 years or older` (Bold label).
    * Checkbox 2: `[✓] I agree to Community Guidelines and Class Terms`.
  * **Bottom:** Full-width primary navy button: *"Continue to Schedule"* (Disabled until both boxes checked).
  * **Footer Label:** *"No account required to follow your class timetable."*

---

### Screen 2: Today View — The Live Schedule Feed (Primary Screen)
* **Purpose:** The core daily glanceable dashboard.
* **Layout Structure:**
  * **AppBar:**
    * Left: Class Name (e.g. *"CSE 3rd Year Sec A"*) with tap-to-edit pencil icon for CR; Subtitle shows *Weekday, Date IST*.
    * Right:
      * **CR Mode / Student Mode** switcher pill (allows instant previewing of student vs editor perspectives).
      * Day Override icon (calendar with rule symbol).
  * **Sub-Header Filter Bar:** Horizontal scrollable choice chips for Batch groups: `[All Classes]`, `[Batch 1 (B1)]`, `[Batch 2 (B2)]`.
  * **Day Override Alert Banner (Dynamic):**
    * *State A (Holiday):* Crimson card with snooze icon: *"No Classes Today — National Holiday"*.
    * *State B (Timetable Swap):* Amber card with exchange arrows icon: *"Day Override: Today follows Friday's timetable"*.
  * **Attendance Margin Quick-Banner:** Soft blue gradient card:
    * Left: Analytics sparkline icon.
    * Text: *"Attendance Margin (75% Target): DBMS: can miss 2 • OS: attend 6 in a row"*.
  * **Class Cards Feed (Vertical List):**
    * **Card Header:** Start Time – End Time (e.g. `10:00 - 11:00`), Group pill (`B1`), Status badge (`Cancelled`, `Room Moved`, `Scheduled`).
    * **Subject Title:** `17px` Bold. If cancelled: struck through in gray.
    * **Location & Faculty Row:** Room pin icon + Room Number (`TP-405`) + Person icon + Faculty name (`Prof. Rajesh K.`).
    * **Editor Notice Banner (if status modified):** Crimson/Amber banner: `"${note} — updated by ${CR_Name}"`.
    * **CR Affordance:** Subtle bottom caption in blue: *"Tap to change status / post to WhatsApp"*.

---

### Screen 3: CR Quick-Action Sheet & WhatsApp Multiplier
* **Purpose:** CR updates class status in under 10 seconds and shares it to WhatsApp in one tap.
* **Layout Structure:**
  * **Modal Bottom Sheet:** Rounded top corners (`24px`), drag handle at center.
  * **Title:** *"Update: Database Management Systems"* with close button (`✕`).
  * **Status Pill Selector (Horizontal wrap):**
    * `[Normal]` (Green)
    * `[Cancelled]` (Red)
    * `[Room Changed]` (Amber)
    * `[Time Moved]` (Orange)
    * `[Extra Class]` (Purple)
  * **Conditional Input:** If `Room Changed` is tapped, a clean text field slides down: *"New Room Number (e.g. Lab 3, TP-502)"*.
  * **Note Input Field:** Outlined input: *"Optional note (e.g. Sir on leave / Bring records)"*.
  * **Action Buttons (Stacked):**
    1. **Primary Button (Navy):** *"Update Status in App"* $\rightarrow$ Triggers toast: *"Status updated • Sent to 58 classmates"*.
    2. **WhatsApp Multiplier Button (WhatsApp Green `#25D366`):** Outlined with WhatsApp logo: *"Save & Post to WhatsApp"*.
       * One tap saves status, formats the message, and opens WhatsApp:
       * *"DBMS 10:00 cancelled today (Sir on leave). Live timetable: https://rostra.ai/p/demo-101"*

---

### Screen 4: Weekly Timetable Grid Editor (CR Studio)
* **Purpose:** Quick creation and adjustment of weekly schedule slots across Monday–Saturday.
* **Layout Structure:**
  * **AppBar:** Title *"Weekly Timetable"* with segmented tabs: `[MON] [TUE] [WED] [THU] [FRI] [SAT]`.
  * **Slot Cards (Chronological):**
    * Leading Time Block: Stacked start/end time in blue container (`09:00 / 10:00`).
    * Subject Name: Bold `16px`.
    * Sub-text: Room Number • Teacher Name • Batch (`B1` / `All`).
    * Action Icons (CR only): Edit pencil icon + Delete trashcan icon.
  * **Floating Action Button:** `+ Add Class Slot` (extended FAB in Navy `#1E3A8A`).
  * **Add/Edit Modal Dialog:**
    * Inputs: Subject Name, Start Time (`HH:mm`), End Time (`HH:mm`), Room Number, Faculty Name, Group Dropdown (`All`, `B1`, `B2`).

---

### Screen 5: Private Attendance Margin Calculator ("Stay Above 75%")
* **Purpose:** Daily retention hook. Solves attendance math with zero server tracking.
* **Layout Structure:**
  * **Target Dial Banner:**
    * Large text: *"Target: 75% Attendance"* with *"Edit Target"* button.
    * Privacy Assurance: Lock icon + *"Private to your phone • 0 server logs"*.
  * **Subject Attendance Cards:**
    * Header: Subject Name + Margin Pill:
      * **Positive Margin:** Green Pill: `+2 Can miss 2 more`.
      * **Deficit Margin:** Red Pill: `-6 Attend 6 in a row`.
    * **Dynamic Cancellation Notice:**
      * If today's class is cancelled by CR: Red badge appears: *"Cancelled today by CR (excluded from held classes)"*.
    * **Progress Bar:** Dual-colored bar showing attendance percentage against the 75% target threshold.
    * **Check-in Action Row:**
      * Left: Current stats: `18 / 22 attended (81.8%)`.
      * Right: Quick action buttons: `[✓ Attended (+1)]` and `[✕ Missed (+1 held)]`.

---

### Screen 6: Public Read-Only Web Page (Mobile Browser)
* **Purpose:** Landing page when classmates tap the WhatsApp link without having the app installed.
* **Layout Structure:**
  * **Brand Pill:** Small logo + *"RostraAI Live Timetable"*.
  * **Header:** Class Title (*"CSE 3rd Year Sec A"*) + College Name (*"SRM Institute"*).
  * **App Banner:** Soft blue highlight container:
    * Text: *"Get changes before you reach the room. Follow this class with one tap."*
    * Action Button: *"Open in App"* (Links via Play Store Install Referrer with `pageId` preserved).
  * **Read-Only Class Cards:** Clean HTML rendering of today's classes, room numbers, and CR cancellation banners.
  * **Zero Clutter:** No follower comments, no ads, loads in `< 200ms`.

---

## 4. Ready-to-Use Prompts for AI UI Generators (Stitch / v0 / Midjourney / Figma)

### Prompt 1: Today View (Live College Schedule)
> **Prompt:**  
> Modern clean mobile UI design for a college student timetable app called "RostraAI". Clean Material 3 style, slate light background (`#F8FAFC`), deep navy primary (`#1E3A8A`).  
> Top AppBar shows class title "CSE 3rd Year Sec A" with subtitle "Wednesday, Oct 7" and a toggle chip for "CR Mode".  
> Below is a horizontal batch filter with pills "All", "Batch 1 (B1)", "Batch 2 (B2)".  
> An attendance margin alert card shows: "Attendance Margin (75% Target): DBMS: can miss 2 • OS: attend 6 in a row".  
> Schedule feed contains 3 rounded white cards:  
> 1. Normal card: "09:00 - 10:00", Green badge "Scheduled", Subject "Operating Systems", Room "TP-301", Teacher "Dr. Anita Verma".  
> 2. Cancelled card: "10:00 - 11:00", Red badge "Cancelled", Subject "Database Management Systems" with strike-through text, Room "TP-405", with a red alert banner saying "Sir on leave today — updated by Sumit (CR)".  
> 3. Lab card: "11:15 - 13:00", Green badge "Scheduled", Subject "DBMS Lab (Batch 1)", Batch tag "B1", Room "Lab 2".  
> Sleek bottom navigation bar with icons for Today, Timetable, Attendance. High contrast, student-focused, zero clutter.

### Prompt 2: CR Quick Action Modal & WhatsApp Share
> **Prompt:**  
> Mobile UI bottom sheet modal design for updating college class status. Darkened backdrop, white bottom sheet with rounded top corners (24px) and a drag handle.  
> Header: "Update: Database Management Systems" with a close (X) icon.  
> Segmented selection chips: "Normal", "Cancelled" (selected, highlighted in red), "Room Changed", "Time Moved", "Extra Class".  
> An outlined input field containing prefilled text: "Sir on leave today".  
> Two full-width action buttons:  
> 1. Solid navy blue button: "Update Status in App".  
> 2. Outlined WhatsApp-green button with WhatsApp icon: "Save & Post to WhatsApp".  
> Floating subtle toast message at bottom: "Status updated • Sent to 58 classmates in CSE 3rd Year Sec A". Ultra clean, crisp typography, intuitive microcopy.

### Prompt 3: Attendance Margin Calculator ("Stay Above 75%")
> **Prompt:**  
> Mobile app UI screen for a private college student attendance tracker with whole-number attendance margins.  
> Top card shows "Target: 75% Attendance" with a slider and small lock icon: "Private to your phone • 0 server logs".  
> Two subject cards on clean white background:  
> Card 1: Subject "Operating Systems", bold green pill "+2 Can miss 2 more", linear progress bar at 82%, text "18 / 22 attended (81.8%)", two circular check-in buttons [✓] and [✕].  
> Card 2: Subject "Database Management Systems", bold red pill "-6 Attend 6 in a row", text "15 / 22 attended (68.2%)", red banner: "Cancelled today by CR (excluded from held classes)", with check-in buttons. Modern fintech/utility aesthetic, clean geometry.
