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

  // --- Role (CR/Editor vs Follower) ---
  bool isEditorMode() {
    return _prefs.getBool(_keyIsEditor) ?? true; // Default true so CR can edit right away
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
}
