import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timetable_models.dart';
import '../core/constants/app_constants.dart';

class TimetableStorage {
  static const String _keyCurrentPage = 'rostraai_cached_page';
  static const String _keyTimetableEntries = 'rostraai_cached_entries';
  static const String _keyDayStatusesPrefix = 'rostraai_cached_status_';
  static const String _keyDayOverridePrefix = 'rostraai_cached_override_';
  static const String _keyIsEditor = 'rostraai_is_editor_mode';
  static const String _keyEditorName = 'rostraai_editor_name';

  final SharedPreferences _prefs;

  TimetableStorage(this._prefs);

  static Future<TimetableStorage> init() async {
    final prefs = await SharedPreferences.getInstance();
    return TimetableStorage(prefs);
  }

  // --- Age 18+ Gate ---
  bool isAgeConfirmed() {
    return _prefs.getBool(AppConstants.keyIsAge18Confirmed) ?? false;
  }

  Future<void> setAgeConfirmed(bool confirmed) async {
    await _prefs.setBool(AppConstants.keyIsAge18Confirmed, confirmed);
  }

  static const String _keyRoleSelected = 'rostraai_role_selected_v1';
  static const String _keyHasSeenGuide = 'rostraai_has_seen_guide_v1';

  // --- Followed Page ID (auto-followed via link/referrer) ---
  String? getFollowedPageId() {
    return _prefs.getString(AppConstants.keyFollowedPageId);
  }

  Future<void> setFollowedPageId(String pageId) async {
    await _prefs.setString(AppConstants.keyFollowedPageId, pageId);
  }

  // --- Role (CR/Editor vs Follower) ---
  bool hasSelectedRole() {
    return _prefs.getBool(_keyRoleSelected) ?? false;
  }

  Future<void> setRoleSelected(bool selected) async {
    await _prefs.setBool(_keyRoleSelected, selected);
  }

  bool hasSeenGuide() {
    return _prefs.getBool(_keyHasSeenGuide) ?? false;
  }

  Future<void> setHasSeenGuide(bool seen) async {
    await _prefs.setBool(_keyHasSeenGuide, seen);
  }

  int getAttendanceTarget() {
    return _prefs.getInt(AppConstants.keyAttendanceTarget) ?? AppConstants.defaultAttendanceTargetPercent;
  }

  Future<void> setAttendanceTarget(int target) async {
    await _prefs.setInt(AppConstants.keyAttendanceTarget, target);
  }

  bool isEditorMode() {
    return _prefs.getBool(_keyIsEditor) ?? false; // Default to student unless CR selected
  }

  Future<void> setEditorMode(bool isEditor) async {
    await _prefs.setBool(_keyIsEditor, isEditor);
  }

  String getEditorName() {
    return _prefs.getString(_keyEditorName) ?? 'Class Representative';
  }

  Future<void> setEditorName(String name) async {
    await _prefs.setString(_keyEditorName, name);
  }

  // --- Active Group ---
  String getSelectedGroup() {
    return _prefs.getString(AppConstants.keySelectedGroup) ?? 'All';
  }

  Future<void> setSelectedGroup(String group) async {
    await _prefs.setString(AppConstants.keySelectedGroup, group);
  }

  // --- Class Page ---
  ClassPage? getPage() {
    final raw = _prefs.getString(_keyCurrentPage);
    if (raw == null) return null;
    try {
      return ClassPage.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> savePage(ClassPage page) async {
    await _prefs.setString(_keyCurrentPage, page.toJson());
  }

  // --- Timetable Entries ---
  List<TimetableEntry> getEntries() {
    final rawList = _prefs.getStringList(_keyTimetableEntries);
    if (rawList == null) return [];
    return rawList.map((str) {
      final map = json.decode(str) as Map<String, dynamic>;
      return TimetableEntry.fromMap(map);
    }).toList();
  }

  Future<void> saveEntries(List<TimetableEntry> entries) async {
    final rawList = entries.map((e) => json.encode(e.toMap())).toList();
    await _prefs.setStringList(_keyTimetableEntries, rawList);
  }

  // --- Day Statuses (per date YYYY-MM-DD) ---
  Map<String, ClassStatus> getStatusesForDate(String date) {
    final raw = _prefs.getString('$_keyDayStatusesPrefix$date');
    if (raw == null) return {};
    final decoded = json.decode(raw) as Map<String, dynamic>;
    return decoded.map((key, val) => MapEntry(key, ClassStatus.fromMap(val as Map<String, dynamic>)));
  }

  Future<void> setStatusForEntry({
    required String date,
    required ClassStatus status,
  }) async {
    final current = getStatusesForDate(date);
    current[status.entryId] = status;
    final encoded = json.encode(current.map((k, v) => MapEntry(k, v.toMap())));
    await _prefs.setString('$_keyDayStatusesPrefix$date', encoded);
  }

  // --- Day Override ---
  DayOverride? getDayOverride(String date) {
    final raw = _prefs.getString('$_keyDayOverridePrefix$date');
    if (raw == null) return null;
    return DayOverride.fromMap(json.decode(raw) as Map<String, dynamic>);
  }

  Future<void> saveDayOverride(DayOverride override) async {
    await _prefs.setString(
      '$_keyDayOverridePrefix${override.date}',
      json.encode(override.toMap()),
    );
  }

  // --- Terms of Use Acceptance ---
  static const String _keyTermsAccepted = 'rostraai_terms_accepted_for_comments';
  bool hasAcceptedTerms() {
    return _prefs.getBool(_keyTermsAccepted) ?? false;
  }

  Future<void> acceptTerms() async {
    await _prefs.setBool(_keyTermsAccepted, true);
  }

  // --- Google Sign-in Mock/State ---
  static const String _keyCurrentUserId = 'rostraai_user_id';
  static const String _keyCurrentUserName = 'rostraai_user_display_name';

  bool isSignedIn() {
    return _prefs.getString(_keyCurrentUserId) != null;
  }

  String getCurrentUserId() {
    return _prefs.getString(_keyCurrentUserId) ?? 'anon-student-1';
  }

  String getCurrentUserName() {
    return _prefs.getString(_keyCurrentUserName) ?? 'Student';
  }

  Future<void> signInWithGoogle({required String userId, required String displayName}) async {
    await _prefs.setString(_keyCurrentUserId, userId);
    await _prefs.setString(_keyCurrentUserName, displayName);
  }

  // --- Moderation & Blocklist ---
  Set<String> getBlockedUsers() {
    final list = _prefs.getStringList(AppConstants.keyBlockedUsers);
    return list != null ? list.toSet() : <String>{};
  }

  Future<void> blockUser(String userId) async {
    final current = getBlockedUsers();
    current.add(userId);
    await _prefs.setStringList(AppConstants.keyBlockedUsers, current.toList());
  }

  Future<void> unblockUser(String userId) async {
    final current = getBlockedUsers();
    current.remove(userId);
    await _prefs.setStringList(AppConstants.keyBlockedUsers, current.toList());
  }

  // --- Comments Storage ---
  static const String _keyCommentsPrefix = 'rostraai_comments_';

  List<ClassComment> getComments({required String date, required String entryId}) {
    final raw = _prefs.getString('$_keyCommentsPrefix${date}_$entryId');
    if (raw == null) return [];
    final list = json.decode(raw) as List<dynamic>;
    final allComments = list.map((m) => ClassComment.fromMap(m as Map<String, dynamic>)).toList();

    final blocked = getBlockedUsers();
    final nowUtc = DateTime.now().toUtc();

    // Filter: Expiry + Blocklist + Moderation rules
    return allComments.where((c) {
      // 1. Expiry filter (midnight IST)
      try {
        final exp = DateTime.parse(c.expiresAt);
        if (nowUtc.isAfter(exp)) return false;
      } catch (_) {}

      // 2. Block filter
      if (blocked.contains(c.authorId)) return false;

      // 3. Moderation filter: Reported follower comments are hidden until reviewed.
      // Reported editor posts stay visible (flagged for review).
      if (c.isReported && !c.isEditor) return false;

      return true;
    }).toList();
  }

  Future<void> saveComments({required String date, required String entryId, required List<ClassComment> comments}) async {
    final encoded = json.encode(comments.map((c) => c.toMap()).toList());
    await _prefs.setString('$_keyCommentsPrefix${date}_$entryId', encoded);
  }

  Future<void> addComment(ClassComment comment) async {
    final raw = _prefs.getString('$_keyCommentsPrefix${comment.classDate}_${comment.entryId}');
    final list = raw != null ? (json.decode(raw) as List<dynamic>).map((m) => ClassComment.fromMap(m as Map<String, dynamic>)).toList() : <ClassComment>[];
    list.add(comment);
    await saveComments(date: comment.classDate, entryId: comment.entryId, comments: list);
  }

  Future<void> reportComment({required String date, required String entryId, required String commentId}) async {
    final raw = _prefs.getString('$_keyCommentsPrefix${date}_$entryId');
    if (raw == null) return;
    final list = (json.decode(raw) as List<dynamic>).map((m) => ClassComment.fromMap(m as Map<String, dynamic>)).toList();
    final updated = list.map((c) {
      if (c.id == commentId) {
        return ClassComment(
          id: c.id,
          classDate: c.classDate,
          entryId: c.entryId,
          authorId: c.authorId,
          authorName: c.authorName,
          isEditor: c.isEditor,
          text: c.text,
          createdAt: c.createdAt,
          expiresAt: c.expiresAt,
          isReported: true,
        );
      }
      return c;
    }).toList();
    await saveComments(date: date, entryId: entryId, comments: updated);
  }
}
