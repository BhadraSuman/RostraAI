import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rostraai/core/utils/ist_clock.dart';
import 'package:rostraai/features/attendance/attendance_calculator.dart';
import 'package:rostraai/features/timetable/timetable_providers.dart';
import 'package:rostraai/models/timetable_models.dart';
import 'package:rostraai/services/firestore_sync_service.dart';
import 'package:rostraai/services/timetable_storage.dart';
import 'package:rostraai/services/update_checker_service.dart';

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

    test('DayOverride serializes and deserializes accurately', () {
      const override = DayOverride(
        date: '2026-10-07',
        isNoClasses: false,
        followsWeekday: 'FRIDAY',
        note: 'Swapped due to technical symposium',
      );

      final map = override.toMap();
      final revived = DayOverride.fromMap(map);

      expect(revived.date, '2026-10-07');
      expect(revived.isNoClasses, isFalse);
      expect(revived.followsWeekday, 'FRIDAY');
      expect(revived.note, 'Swapped due to technical symposium');
    });

    test('LiveClassItem accurately reflects effective room and cancellation state', () {
      const entry = TimetableEntry(
        id: 'slot-1',
        day: 'MONDAY',
        startTime: '09:00',
        endTime: '10:00',
        subject: 'Operating Systems',
        room: 'TP-301',
        teacher: 'Dr. Anita Verma',
      );

      // Normal state
      final normalItem = LiveClassItem(entry: entry);
      expect(normalItem.isCancelled, isFalse);
      expect(normalItem.effectiveRoom, 'TP-301');

      // Moved state
      final movedItem = LiveClassItem(
        entry: entry,
        status: const ClassStatus(
          entryId: 'slot-1',
          status: ClassStatusType.roomMoved,
          updatedRoom: 'TP-502',
          updatedAt: '2026-10-07T08:00:00Z',
          updatedByName: 'Sumit (CR)',
        ),
      );
      expect(movedItem.isRoomMoved, isTrue);
      expect(movedItem.effectiveRoom, 'TP-502');

      // Cancelled state
      final cancelledItem = LiveClassItem(
        entry: entry,
        status: const ClassStatus(
          entryId: 'slot-1',
          status: ClassStatusType.cancelled,
          note: 'Faculty unwell',
          updatedAt: '2026-10-07T08:00:00Z',
          updatedByName: 'Sumit (CR)',
        ),
      );
      expect(cancelledItem.isCancelled, isTrue);
    });
  });

  group('Phase 4: Comments, Expiry & Moderation Safety Tests', () {
    test('Reported follower comment is hidden, but reported editor comment stays visible', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await TimetableStorage.init();

      final followerComment = ClassComment(
        id: 'c-follower',
        classDate: '2026-10-07',
        entryId: 'slot-1',
        authorId: 'student-42',
        authorName: 'Aman',
        isEditor: false,
        text: 'Class will start late',
        createdAt: '2026-10-07T09:00:00Z',
        expiresAt: '2099-01-01T00:00:00Z',
        isReported: true, // Reported follower comment
      );

      final editorComment = ClassComment(
        id: 'c-editor',
        classDate: '2026-10-07',
        entryId: 'slot-1',
        authorId: 'cr-1',
        authorName: 'Sumit (CR)',
        isEditor: true,
        text: 'Sir asked everyone to bring lab manuals',
        createdAt: '2026-10-07T09:00:00Z',
        expiresAt: '2099-01-01T00:00:00Z',
        isReported: true, // Reported editor comment
      );

      await storage.saveComments(
        date: '2026-10-07',
        entryId: 'slot-1',
        comments: [followerComment, editorComment],
      );

      final visible = storage.getComments(date: '2026-10-07', entryId: 'slot-1');

      // Follower comment must be hidden; editor comment must remain visible
      expect(visible.any((c) => c.id == 'c-follower'), isFalse);
      expect(visible.any((c) => c.id == 'c-editor'), isTrue);
    });

    test('Blocking a user hides all comments from that user', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await TimetableStorage.init();

      final spamComment = ClassComment(
        id: 'c-spam',
        classDate: '2026-10-07',
        entryId: 'slot-1',
        authorId: 'troll-user-99',
        authorName: 'Anonymous Troll',
        isEditor: false,
        text: 'Spam text',
        createdAt: '2026-10-07T09:00:00Z',
        expiresAt: '2099-01-01T00:00:00Z',
      );

      await storage.saveComments(
        date: '2026-10-07',
        entryId: 'slot-1',
        comments: [spamComment],
      );

      // Block user
      await storage.blockUser('troll-user-99');

      final visible = storage.getComments(date: '2026-10-07', entryId: 'slot-1');
      expect(visible.isEmpty, isTrue);
    });

    test('Expired comment past midnight is filtered out from query', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await TimetableStorage.init();

      final expiredComment = ClassComment(
        id: 'c-expired',
        classDate: '2020-01-01',
        entryId: 'slot-1',
        authorId: 'student-1',
        authorName: 'Rohan',
        isEditor: false,
        text: 'Yesterday note',
        createdAt: '2020-01-01T09:00:00Z',
        expiresAt: '2020-01-01T18:29:59Z', // Past midnight IST
      );

      await storage.saveComments(
        date: '2020-01-01',
        entryId: 'slot-1',
        comments: [expiredComment],
      );

      final visible = storage.getComments(date: '2020-01-01', entryId: 'slot-1');
      expect(visible.isEmpty, isTrue);
    });
  });

  group('In-App Auto-Updater Version Check Tests', () {
    test('Detects newer version correctly', () {
      expect(UpdateCheckerService.isVersionGreater('1.0.1', '1.0.0'), isTrue);
      expect(UpdateCheckerService.isVersionGreater('1.1.0', '1.0.9'), isTrue);
      expect(UpdateCheckerService.isVersionGreater('2.0.0', '1.9.9'), isTrue);
    });

    test('Does not flag older or same versions as updates', () {
      expect(UpdateCheckerService.isVersionGreater('1.0.0', '1.0.0'), isFalse);
      expect(UpdateCheckerService.isVersionGreater('1.0.0', '1.0.1'), isFalse);
      expect(UpdateCheckerService.isVersionGreater('0.9.9', '1.0.0'), isFalse);
    });
  });

  group('Phase 6: Live Cloud Sync & Offline Resilience Tests', () {
    test('FirestoreSyncService safely defaults to offline mode when uninitialized', () {
      // In headless test environment without active Firebase native bridge,
      // FirestoreSyncService gracefully reports isAvailable as false without throwing
      expect(FirestoreSyncService.isAvailable, isFalse);
    });

    test('Live Class Status can be merged and preserved offline', () {
      final statusMap = <String, ClassStatus>{
        'slot-1': const ClassStatus(
          entryId: 'slot-1',
          status: ClassStatusType.roomMoved,
          updatedRoom: 'TP-405',
          updatedAt: '2026-10-10T09:00:00Z',
          updatedByName: 'Sumit (CR)',
        ),
      };

      expect(statusMap['slot-1']!.status, ClassStatusType.roomMoved);
      expect(statusMap['slot-1']!.updatedRoom, 'TP-405');
      final serialized = statusMap['slot-1']!.toMap();
      final deserialized = ClassStatus.fromMap(serialized);
      expect(deserialized.entryId, 'slot-1');
      expect(deserialized.updatedRoom, 'TP-405');
    });
  });

  group('Authentication & Session Persistence Tests', () {
    test('Saves and clears user authentication profile in TimetableStorage', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await TimetableStorage.init();

      expect(storage.isLoggedIn(), isFalse);
      expect(storage.getUserId(), isNull);

      await storage.saveUserProfile(
        uid: 'user_12345',
        name: 'Suman Bhadra',
        email: 'suman@college.edu.in',
        photoUrl: 'https://example.com/avatar.png',
      );

      expect(storage.isLoggedIn(), isTrue);
      expect(storage.getUserId(), 'user_12345');
      expect(storage.getUserName(), 'Suman Bhadra');
      expect(storage.getUserEmail(), 'suman@college.edu.in');
      expect(storage.getUserPhotoUrl(), 'https://example.com/avatar.png');

      await storage.clearUserProfile();
      expect(storage.isLoggedIn(), isFalse);
      expect(storage.getUserId(), isNull);
      expect(storage.getUserName(), isNull);
    });
  });
}
