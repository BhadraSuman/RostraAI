import 'package:flutter_test/flutter_test.dart';
import 'package:rostraai/core/utils/ist_clock.dart';
import 'package:rostraai/features/attendance/attendance_calculator.dart';
import 'package:rostraai/models/timetable_models.dart';

void main() {
  group('Attendance Margin Integer Math Tests (CampusFlow v0.3 spec)', () {
    test('18 attended of 22 held at 75% gives margin of +2 (can miss 2)', () {
      final margin = calculateAttendanceMargin(18, 22, 75);
      expect(margin, 2);
    });

    test('15 attended of 22 held at 75% gives margin of -6 (must attend 6 in a row)', () {
      final margin = calculateAttendanceMargin(15, 22, 75);
      expect(margin, -6);
    });

    test('20 attended of 20 held at 75% gives positive surplus', () {
      final margin = calculateAttendanceMargin(20, 20, 75);
      expect(margin, 6); // (2000 - 1500) ~/ 75 = 500 ~/ 75 = 6
    });

    test('0 classes held returns 0 without crashing', () {
      final margin = calculateAttendanceMargin(0, 0, 75);
      expect(margin, 0);
    });
  });

  group('IST Clock and Expiry Tests', () {
    test('IstClock formats date as YYYY-MM-DD', () {
      final dateStr = IstClock.todayDateString();
      expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateStr), isTrue);
    });

    test('Midnight expiry IST accurately calculates future vs past', () {
      final pastDate = '2020-01-01';
      final expiryUtc = IstClock.midnightExpiryIst(pastDate);
      expect(IstClock.hasExpired(expiryUtc), isTrue);

      final futureDate = '2099-01-01';
      final futureExpiryUtc = IstClock.midnightExpiryIst(futureDate);
      expect(IstClock.hasExpired(futureExpiryUtc), isFalse);
    });
  });

  group('Timetable Storage & Domain Model Serialization', () {
    test('TimetableEntry maps to and from Map', () {
      const entry = TimetableEntry(
        id: 'test-1',
        day: 'MONDAY',
        startTime: '10:00',
        endTime: '11:00',
        subject: 'Database Management Systems',
        room: 'TP-405',
        teacher: 'Prof. Rajesh K.',
        group: 'B1',
      );

      final map = entry.toMap();
      final revived = TimetableEntry.fromMap(map);

      expect(revived.id, entry.id);
      expect(revived.subject, entry.subject);
      expect(revived.room, entry.room);
      expect(revived.teacher, entry.teacher);
      expect(revived.group, entry.group);
    });

    test('ClassStatus correctly maps status changes and notes', () {
      final status = ClassStatus(
        entryId: 'test-1',
        status: ClassStatusType.cancelled,
        note: 'Sir on leave',
        updatedAt: '2026-10-07T10:00:00Z',
        updatedByName: 'Sumit (CR)',
      );

      final map = status.toMap();
      final revived = ClassStatus.fromMap(map);

      expect(revived.status, ClassStatusType.cancelled);
      expect(revived.note, 'Sir on leave');
      expect(revived.updatedByName, 'Sumit (CR)');
    });
  });
}
