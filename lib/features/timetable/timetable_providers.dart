import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/ist_clock.dart';
import '../../models/timetable_models.dart';
import '../../services/firestore_sync_service.dart';
import '../../services/timetable_storage.dart';

final storageProvider = Provider<TimetableStorage>((ref) {
  throw UnimplementedError('Storage provider must be overridden with initialized instance');
});

// --- CR Mode vs Follower Mode ---
class IsEditorNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(storageProvider).isEditorMode();
  }

  void toggle() {
    state = !state;
    ref.read(storageProvider).setEditorMode(state);
  }

  void setMode(bool isEditor) {
    state = isEditor;
    ref.read(storageProvider).setEditorMode(isEditor);
  }
}

final isEditorModeProvider = NotifierProvider<IsEditorNotifier, bool>(IsEditorNotifier.new);

// --- Active Group (e.g. All, B1, B2) ---
class ActiveGroupNotifier extends Notifier<String> {
  @override
  String build() {
    return ref.watch(storageProvider).getSelectedGroup();
  }

  void setGroup(String group) {
    state = group;
    ref.read(storageProvider).setSelectedGroup(group);
  }
}

final activeGroupProvider = NotifierProvider<ActiveGroupNotifier, String>(ActiveGroupNotifier.new);

// --- Class Page ---
class CurrentPageNotifier extends Notifier<ClassPage?> {
  @override
  ClassPage? build() {
    return ref.watch(storageProvider).getPage();
  }

  Future<void> updatePage(ClassPage page) async {
    state = page;
    await ref.read(storageProvider).savePage(page);
  }

  Future<void> createDefaultPageIfEmpty() async {
    if (state != null) return;
    const defaultPage = ClassPage(
      id: 'demo-class-101',
      college: 'SRM Institute of Science and Technology',
      department: 'Computer Science & Engineering',
      year: '3rd Year',
      section: 'Section A',
      createdBy: 'cr-user-1',
      createdByName: 'Sumit (CR)',
      editors: ['cr-user-1'],
      availableGroups: ['All', 'B1', 'B2'],
    );
    await updatePage(defaultPage);
  }
}

final currentPageProvider = NotifierProvider<CurrentPageNotifier, ClassPage?>(CurrentPageNotifier.new);

// --- Weekly Timetable Entries ---
class TimetableEntriesNotifier extends Notifier<List<TimetableEntry>> {
  @override
  List<TimetableEntry> build() {
    return ref.watch(storageProvider).getEntries();
  }

  Future<void> addEntry({
    required String day,
    required String startTime,
    required String endTime,
    required String subject,
    required String room,
    required String teacher,
    String group = 'All',
    String? courseCode,
  }) async {
    final newEntry = TimetableEntry(
      id: const Uuid().v4(),
      day: day.toUpperCase(),
      startTime: startTime,
      endTime: endTime,
      subject: subject,
      room: room,
      teacher: teacher,
      group: group,
      courseCode: courseCode,
    );
    state = [...state, newEntry];
    await ref.read(storageProvider).saveEntries(state);
    _syncToCloud();
  }

  Future<void> updateEntry(TimetableEntry updated) async {
    state = state.map((e) => e.id == updated.id ? updated : e).toList();
    await ref.read(storageProvider).saveEntries(state);
    _syncToCloud();
  }

  Future<void> removeEntry(String id) async {
    state = state.where((e) => e.id != id).toList();
    await ref.read(storageProvider).saveEntries(state);
    _syncToCloud();
  }

  void _syncToCloud() {
    final page = ref.read(currentPageProvider);
    final pageId = page?.id ?? 'demo-class-101';
    FirestoreSyncService.syncTimetable(pageId: pageId, entries: state);
  }

  Future<void> seedSampleSchedule() async {
    if (state.isNotEmpty) return;
    final sample = <TimetableEntry>[
      // Monday
      const TimetableEntry(
        id: 'mon-1',
        day: 'MONDAY',
        startTime: '09:00',
        endTime: '10:00',
        subject: 'Operating Systems',
        room: 'TP-301',
        teacher: 'Dr. Anita Verma',
        group: 'All',
      ),
      const TimetableEntry(
        id: 'mon-2',
        day: 'MONDAY',
        startTime: '10:00',
        endTime: '11:00',
        subject: 'Database Management Systems',
        room: 'TP-405',
        teacher: 'Prof. Rajesh K.',
        group: 'All',
      ),
      const TimetableEntry(
        id: 'mon-3',
        day: 'MONDAY',
        startTime: '11:15',
        endTime: '13:00',
        subject: 'DBMS Lab (Batch 1)',
        room: 'Lab 2',
        teacher: 'Prof. Rajesh K.',
        group: 'B1',
      ),
      const TimetableEntry(
        id: 'mon-4',
        day: 'MONDAY',
        startTime: '11:15',
        endTime: '13:00',
        subject: 'Networks Lab (Batch 2)',
        room: 'Lab 4',
        teacher: 'Dr. P. Sen',
        group: 'B2',
      ),
      // Tuesday
      const TimetableEntry(
        id: 'tue-1',
        day: 'TUESDAY',
        startTime: '09:00',
        endTime: '10:00',
        subject: 'Computer Networks',
        room: 'TP-301',
        teacher: 'Dr. P. Sen',
        group: 'All',
      ),
      const TimetableEntry(
        id: 'tue-2',
        day: 'TUESDAY',
        startTime: '10:00',
        endTime: '11:00',
        subject: 'Design & Analysis of Algorithms',
        room: 'TP-204',
        teacher: 'Dr. V. Raman',
        group: 'All',
      ),
      // Wednesday
      const TimetableEntry(
        id: 'wed-1',
        day: 'WEDNESDAY',
        startTime: '09:00',
        endTime: '10:00',
        subject: 'Database Management Systems',
        room: 'TP-405',
        teacher: 'Prof. Rajesh K.',
        group: 'All',
      ),
      const TimetableEntry(
        id: 'wed-2',
        day: 'WEDNESDAY',
        startTime: '10:00',
        endTime: '11:00',
        subject: 'Operating Systems',
        room: 'TP-301',
        teacher: 'Dr. Anita Verma',
        group: 'All',
      ),
      // Thursday
      const TimetableEntry(
        id: 'thu-1',
        day: 'THURSDAY',
        startTime: '09:00',
        endTime: '10:00',
        subject: 'Design & Analysis of Algorithms',
        room: 'TP-204',
        teacher: 'Dr. V. Raman',
        group: 'All',
      ),
      const TimetableEntry(
        id: 'thu-2',
        day: 'THURSDAY',
        startTime: '10:00',
        endTime: '11:00',
        subject: 'Computer Networks',
        room: 'TP-301',
        teacher: 'Dr. P. Sen',
        group: 'All',
      ),
      // Friday
      const TimetableEntry(
        id: 'fri-1',
        day: 'FRIDAY',
        startTime: '09:00',
        endTime: '10:00',
        subject: 'Operating Systems',
        room: 'TP-301',
        teacher: 'Dr. Anita Verma',
        group: 'All',
      ),
      const TimetableEntry(
        id: 'fri-2',
        day: 'FRIDAY',
        startTime: '10:00',
        endTime: '11:00',
        subject: 'Database Management Systems',
        room: 'TP-405',
        teacher: 'Prof. Rajesh K.',
        group: 'All',
      ),
      // Saturday
      const TimetableEntry(
        id: 'sat-1',
        day: 'SATURDAY',
        startTime: '10:00',
        endTime: '12:00',
        subject: 'Project Mentorship',
        room: 'Seminar Hall 1',
        teacher: 'Dr. Anita Verma',
        group: 'All',
      ),
    ];
    state = sample;
    await ref.read(storageProvider).saveEntries(sample);
  }
}

final timetableEntriesProvider = NotifierProvider<TimetableEntriesNotifier, List<TimetableEntry>>(TimetableEntriesNotifier.new);

// --- Today's Day Override Provider ---
class TodayOverrideNotifier extends Notifier<DayOverride?> {
  @override
  DayOverride? build() {
    final today = IstClock.todayDateString();
    return ref.watch(storageProvider).getDayOverride(today);
  }

  void updateFromCloud(DayOverride? override) {
    state = override;
  }

  Future<void> setOverride({
    required bool isNoClasses,
    String? followsWeekday,
    String? note,
  }) async {
    final today = IstClock.todayDateString();
    final override = DayOverride(
      date: today,
      isNoClasses: isNoClasses,
      followsWeekday: followsWeekday,
      note: note,
    );
    await ref.read(storageProvider).saveDayOverride(override);
    state = override;

    // Push to Cloud Firestore for real-time sync with followers
    final page = ref.read(currentPageProvider);
    final pageId = page?.id ?? 'demo-class-101';
    await FirestoreSyncService.syncDayOverride(
      pageId: pageId,
      override: override,
    );
  }

  Future<void> clearOverride() async {
    final today = IstClock.todayDateString();
    final cleared = DayOverride(date: today, isNoClasses: false);
    await ref.read(storageProvider).saveDayOverride(cleared);
    state = null;

    final page = ref.read(currentPageProvider);
    final pageId = page?.id ?? 'demo-class-101';
    await FirestoreSyncService.syncDayOverride(
      pageId: pageId,
      override: cleared,
    );
  }
}

final todayOverrideProvider = NotifierProvider<TodayOverrideNotifier, DayOverride?>(TodayOverrideNotifier.new);

// --- Today's Class Statuses Provider ---
class TodayStatusesNotifier extends Notifier<Map<String, ClassStatus>> {
  @override
  Map<String, ClassStatus> build() {
    final today = IstClock.todayDateString();
    return ref.watch(storageProvider).getStatusesForDate(today);
  }

  void updateAll(Map<String, ClassStatus> statuses) {
    state = {...state, ...statuses};
  }

  Future<void> setStatus({
    required String entryId,
    required ClassStatusType status,
    String? note,
    String? updatedRoom,
    String? updatedStartTime,
    String? updatedEndTime,
    required String editorName,
  }) async {
    final today = IstClock.todayDateString();
    final classStatus = ClassStatus(
      entryId: entryId,
      status: status,
      note: note,
      updatedRoom: updatedRoom,
      updatedStartTime: updatedStartTime,
      updatedEndTime: updatedEndTime,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
      updatedByName: editorName,
    );

    await ref.read(storageProvider).setStatusForEntry(date: today, status: classStatus);
    state = {...state, entryId: classStatus};

    // Push to Cloud Firestore for real-time sync with followers
    final page = ref.read(currentPageProvider);
    final pageId = page?.id ?? 'demo-class-101';
    await FirestoreSyncService.syncStatus(
      pageId: pageId,
      date: today,
      status: classStatus,
    );
  }
}

final todayStatusesProvider = NotifierProvider<TodayStatusesNotifier, Map<String, ClassStatus>>(TodayStatusesNotifier.new);

// --- Combined Live Class Item for Today View ---
class LiveClassItem {
  final TimetableEntry entry;
  final ClassStatus? status;

  const LiveClassItem({required this.entry, this.status});

  bool get isCancelled => status?.status == ClassStatusType.cancelled;
  bool get isRoomMoved => status?.status == ClassStatusType.roomMoved;
  bool get isTimeMoved => status?.status == ClassStatusType.timeMoved;
  bool get isExtraClass => status?.status == ClassStatusType.extraClass;

  String get effectiveRoom => status?.updatedRoom ?? entry.room;
  String get effectiveStartTime => status?.updatedStartTime ?? entry.startTime;
  String get effectiveEndTime => status?.updatedEndTime ?? entry.endTime;
}

// --- Today's Computed Schedule Provider (Considers Day Overrides) ---
final todayScheduleProvider = Provider<List<LiveClassItem>>((ref) {
  final override = ref.watch(todayOverrideProvider);
  if (override != null && override.isNoClasses) {
    return [];
  }

  final targetWeekday = (override?.followsWeekday != null && override!.followsWeekday!.isNotEmpty)
      ? override.followsWeekday!.toUpperCase()
      : IstClock.weekdayName();

  final entries = ref.watch(timetableEntriesProvider);
  final activeGroup = ref.watch(activeGroupProvider);
  final statuses = ref.watch(todayStatusesProvider);

  // Filter entries for target weekday
  final dayEntries = entries.where((e) => e.day == targetWeekday).toList();

  // Filter by active group: classes for 'All' or user's specific group
  final filtered = dayEntries.where((e) {
    if (activeGroup == 'All') return true;
    return e.group == 'All' || e.group == activeGroup;
  }).toList();

  // Map to LiveClassItem and sort by start time
  final liveItems = filtered.map((e) {
    return LiveClassItem(entry: e, status: statuses[e.id]);
  }).toList();

  liveItems.sort((a, b) => a.effectiveStartTime.compareTo(b.effectiveStartTime));
  return liveItems;
});

// --- Guided Walkthrough & Navigation State ---
class HasSeenGuideNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(storageProvider).hasSeenGuide();
  }

  void markAsSeen() {
    state = true;
    ref.read(storageProvider).setHasSeenGuide(true);
  }

  void showGuide() {
    state = false;
    ref.read(storageProvider).setHasSeenGuide(false);
  }
}

final hasSeenGuideProvider = NotifierProvider<HasSeenGuideNotifier, bool>(
  HasSeenGuideNotifier.new,
);

class BottomNavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int idx) => state = idx;
}

final bottomNavIndexProvider = NotifierProvider<BottomNavIndexNotifier, int>(
  BottomNavIndexNotifier.new,
);

