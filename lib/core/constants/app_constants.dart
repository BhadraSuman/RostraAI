class AppConstants {
  static const String appName = 'RostraAI';
  static const String appTagline = 'Class changes before you reach the room';
  static const String appVersion = '1.0.1';
  static const String githubRepo = 'bhadrasuman/RostraAI';

  // Attendance
  static const int defaultAttendanceTargetPercent = 75;

  // Timezone
  static const String timezone = 'Asia/Kolkata';
  static const Duration istOffset = Duration(hours: 5, minutes: 30);

  // Storage Keys
  static const String keyIsAge18Confirmed = 'rostraai_age_18_confirmed';
  static const String keyFollowedPageId = 'rostraai_followed_page_id';
  static const String keySelectedGroup = 'rostraai_selected_group';
  static const String keyAttendanceTarget = 'rostraai_attendance_target';
  static const String keyLocalAttendanceRecords = 'rostraai_attendance_records_v1';
  static const String keyBlockedUsers = 'rostraai_blocked_users';
}
