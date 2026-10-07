import 'package:intl/intl.dart';

class IstClock {
  static const Duration _istOffset = Duration(hours: 5, minutes: 30);

  /// Returns current DateTime in Indian Standard Time (UTC+05:30).
  static DateTime nowIst() {
    return DateTime.now().toUtc().add(_istOffset);
  }

  /// Formats a DateTime as YYYY-MM-DD in IST.
  static String todayDateString([DateTime? dt]) {
    final target = (dt ?? nowIst());
    return DateFormat('yyyy-MM-dd').format(target);
  }

  /// Returns Monday-Saturday weekday name in upper case e.g. "MONDAY".
  static String weekdayName([DateTime? dt]) {
    final target = (dt ?? nowIst());
    switch (target.weekday) {
      case DateTime.monday:
        return 'MONDAY';
      case DateTime.tuesday:
        return 'TUESDAY';
      case DateTime.wednesday:
        return 'WEDNESDAY';
      case DateTime.thursday:
        return 'THURSDAY';
      case DateTime.friday:
        return 'FRIDAY';
      case DateTime.saturday:
        return 'SATURDAY';
      case DateTime.sunday:
      default:
        return 'SUNDAY';
    }
  }

  /// Returns DateTime representing 23:59:59.999 IST for a given date string (YYYY-MM-DD).
  static DateTime midnightExpiryIst(String dateString) {
    final parts = dateString.split('-').map(int.parse).toList();
    // 23:59:59 IST is 18:29:59 UTC
    final istMidnight = DateTime.utc(parts[0], parts[1], parts[2], 23, 59, 59);
    // Convert to actual UTC timestamp
    return istMidnight.subtract(_istOffset);
  }

  /// Checks if a given timestamp has passed midnight IST for its class date.
  static bool hasExpired(DateTime expiresAtUtc) {
    return DateTime.now().toUtc().isAfter(expiresAtUtc);
  }
}
