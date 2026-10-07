import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';

class AttendanceRecord {
  final String subject;
  final int attended;
  final int held;

  const AttendanceRecord({
    required this.subject,
    required this.attended,
    required this.held,
  });

  AttendanceRecord copyWith({int? attended, int? held}) {
    return AttendanceRecord(
      subject: subject,
      attended: attended ?? this.attended,
      held: held ?? this.held,
    );
  }

  double get percentage => held > 0 ? (attended / held) * 100 : 100.0;
}

/// Official CampusFlow v0.3 Integer Math Attendance Margin Formula.
/// a = attended, h = held, p = target percentage (e.g. 75).
/// Returns positive if student can miss N more classes,
/// Returns negative if student must attend |N| classes in a row.
int calculateAttendanceMargin(int a, int h, int p) {
  if (h <= 0) return 0;
  final surplus = 100 * a - p * h;
  if (surplus >= 0) {
    return surplus ~/ p;
  }
  final q = 100 - p;
  return -((-surplus + q - 1) ~/ q);
}

// Attendance State
class AttendanceState {
  final int targetPercent;
  final Map<String, AttendanceRecord> records;

  const AttendanceState({
    this.targetPercent = AppConstants.defaultAttendanceTargetPercent,
    this.records = const {},
  });

  AttendanceState copyWith({
    int? targetPercent,
    Map<String, AttendanceRecord>? records,
  }) {
    return AttendanceState(
      targetPercent: targetPercent ?? this.targetPercent,
      records: records ?? this.records,
    );
  }
}

class AttendanceNotifier extends Notifier<AttendanceState> {
  @override
  AttendanceState build() {
    // Seed sample subjects for immediate feedback if empty
    return const AttendanceState(
      targetPercent: 75,
      records: {
        'Operating Systems': AttendanceRecord(subject: 'Operating Systems', attended: 18, held: 22),
        'Database Management Systems': AttendanceRecord(subject: 'Database Management Systems', attended: 15, held: 22),
        'Computer Networks': AttendanceRecord(subject: 'Computer Networks', attended: 20, held: 22),
        'Design & Analysis of Algorithms': AttendanceRecord(subject: 'Design & Analysis of Algorithms', attended: 16, held: 20),
      },
    );
  }

  void markAttended(String subject) {
    final current = state.records[subject] ?? AttendanceRecord(subject: subject, attended: 0, held: 0);
    final updated = current.copyWith(
      attended: current.attended + 1,
      held: current.held + 1,
    );
    state = state.copyWith(records: {...state.records, subject: updated});
  }

  void markMissed(String subject) {
    final current = state.records[subject] ?? AttendanceRecord(subject: subject, attended: 0, held: 0);
    final updated = current.copyWith(
      held: current.held + 1,
    );
    state = state.copyWith(records: {...state.records, subject: updated});
  }

  void setCustomCount(String subject, int attended, int held) {
    final updated = AttendanceRecord(subject: subject, attended: attended, held: held);
    state = state.copyWith(records: {...state.records, subject: updated});
  }

  void setTargetPercent(int percent) {
    state = state.copyWith(targetPercent: percent);
  }
}

final attendanceProvider = NotifierProvider<AttendanceNotifier, AttendanceState>(AttendanceNotifier.new);
