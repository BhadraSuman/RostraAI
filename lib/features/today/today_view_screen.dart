import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../attendance/attendance_calculator.dart';
import '../navigation/app_sidebar_drawer.dart';
import '../timetable/timetable_providers.dart';

// State preview modes to demonstrate each Stitch screen
enum StitchDemoState { normal, crMode, dayOverride, holiday, offline, skeleton }

class StitchDemoStateNotifier extends Notifier<StitchDemoState> {
  @override
  StitchDemoState build() => StitchDemoState.normal;

  void setDemoState(StitchDemoState value) => state = value;
}

final stitchDemoStateProvider = NotifierProvider<StitchDemoStateNotifier, StitchDemoState>(
  StitchDemoStateNotifier.new,
);

class TodayViewScreen extends ConsumerWidget {
  const TodayViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(currentPageProvider);
    final isEditorReal = ref.watch(isEditorModeProvider);
    final demoState = ref.watch(stitchDemoStateProvider);
    final attendanceState = ref.watch(attendanceProvider);
    final todaySchedule = ref.watch(todayScheduleProvider);
    final activeGroup = ref.watch(activeGroupProvider);

    // If demoState is crMode, reflect editor; if normal, follower mode; etc.
    final isEditor = demoState == StitchDemoState.crMode || (demoState == StitchDemoState.normal && isEditorReal);
    final isSkeleton = demoState == StitchDemoState.skeleton;
    final isHoliday = demoState == StitchDemoState.holiday;
    final isOffline = demoState == StitchDemoState.offline;
    final isDayOverride = demoState == StitchDemoState.dayOverride;

    final hasSeenGuide = ref.watch(hasSeenGuideProvider);

    if (isSkeleton) {
      return _buildSkeletonScreen(context, ref);
    }

    return Scaffold(
      backgroundColor: AppTheme.canvasPaper,
      drawer: AppSidebarDrawer(
        currentTabIndex: 0,
        onSelectTab: (idx) {
          ref.read(bottomNavIndexProvider.notifier).setIndex(idx);
        },
        onOpenGuide: () {
          ref.read(hasSeenGuideProvider.notifier).showGuide();
        },
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppTheme.textStone900, size: 24),
            tooltip: 'Open navigation drawer',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppTheme.burntOrange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.notifications_active_rounded, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Today',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textStone900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () {
                        // Toggle CR mode
                        final next = isEditor ? StitchDemoState.normal : StitchDemoState.crMode;
                        ref.read(stitchDemoStateProvider.notifier).setDemoState(next);
                        ref.read(isEditorModeProvider.notifier).toggle();
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.peachTint,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isEditor ? '⚡ CR mode' : '(CR)',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.burntOrange,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      isEditor ? 'CSE 3rd Year • Sec A' : 'SRM Institute • 58 following',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textStone500,
                      ),
                    ),
                    if (isEditor) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.edit_outlined, size: 11, color: AppTheme.burntOrange),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Quick Switcher icon to preview any Stitch state (Normal, CR, Day Override, Holiday, Offline, Skeleton)
          PopupMenuButton<StitchDemoState>(
            icon: const Icon(Icons.palette_outlined, size: 20, color: AppTheme.burntOrange),
            tooltip: 'Preview Stitch Screen States',
            onSelected: (val) {
              ref.read(stitchDemoStateProvider.notifier).setDemoState(val);
              if (val == StitchDemoState.crMode) {
                ref.read(isEditorModeProvider.notifier).toggle();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: StitchDemoState.normal,
                child: Text('1. Today - Glance Dashboard'),
              ),
              const PopupMenuItem(
                value: StitchDemoState.crMode,
                child: Text('2. Today - CR Mode Dashboard'),
              ),
              const PopupMenuItem(
                value: StitchDemoState.dayOverride,
                child: Text('3. Today - Day Override State'),
              ),
              const PopupMenuItem(
                value: StitchDemoState.holiday,
                child: Text('4. Today - Holiday State'),
              ),
              const PopupMenuItem(
                value: StitchDemoState.offline,
                child: Text('5. Today - Offline State'),
              ),
              const PopupMenuItem(
                value: StitchDemoState.skeleton,
                child: Text('6. Today - Loading Skeleton State'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.textStone700),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF7C2D12),
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome / Guided Tour Banner (dismissible)
            if (!hasSeenGuide) ...[
              _buildWelcomeGuideBanner(context, ref, isEditor),
              const SizedBox(height: 12),
            ],

            // Sync status strip
            _buildSyncStrip(isOffline),
            const SizedBox(height: 10),

            // State specific top banner (Override, Holiday, or Offline banner)
            if (isDayOverride) ...[
              _buildDayOverrideBanner(),
              const SizedBox(height: 12),
            ] else if (isHoliday) ...[
              _buildHolidayBanner(),
              const SizedBox(height: 12),
            ] else if (isOffline) ...[
              _buildOfflineBanner(),
              const SizedBox(height: 12),
            ],

            // Hero Card
            if (isHoliday) ...[
              _buildHolidayHeroCard(context),
            ] else ...[
              _buildNormalHeroCard(isOffline, isDayOverride),
            ],
            const SizedBox(height: 16),

            // Attendance Check Widget (or cached attendance)
            if (isHoliday) ...[
              _buildHolidayAttendanceOverview(attendanceState),
            ] else if (isOffline) ...[
              _buildOfflineAttendanceCard(),
            ] else ...[
              _buildAttendanceCheckRow(context, attendanceState),
            ],
            const SizedBox(height: 16),

            // Filter Chips
            if (!isHoliday) ...[
              _buildFilterChips(ref, activeGroup),
              const SizedBox(height: 16),
            ],

            // Schedule Header & Timeline Items
            if (!isHoliday) ...[
              _buildScheduleHeader(isDayOverride, isOffline),
              const SizedBox(height: 12),
              _buildScheduleTimeline(context, ref, todaySchedule, isEditor, isDayOverride, isOffline, page?.id ?? 'demo-class-101'),
            ] else ...[
              // Free slot / coffee shop card in holiday
              _buildHolidayCoffeeCard(),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeGuideBanner(BuildContext context, WidgetRef ref, bool isEditor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.peachBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.burntOrange.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.burntOrange.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.peachTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isEditor ? Icons.bolt_rounded : Icons.lightbulb_rounded,
                  size: 18,
                  color: AppTheme.burntOrange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditor ? 'CR Mode Active • Quick Guide' : 'Welcome to RostraAI • Quick Guide',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.burntOrange,
                      ),
                    ),
                    Text(
                      isEditor
                          ? 'You have admin tools to manage classes and broadcast changes.'
                          : 'Never reach an empty classroom again. Here is how your schedule works:',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: AppTheme.textStone600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textStone400),
                tooltip: 'Dismiss guide',
                onPressed: () {
                  ref.read(hasSeenGuideProvider.notifier).markAsSeen();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppTheme.peachTint),
          const SizedBox(height: 10),
          if (!isEditor) ...[
            _buildGuideBullet('🟢 Live Status Pills', 'Green = Normal, Red = Cancelled, Amber = Moved room.'),
            _buildGuideBullet('📊 Attendance Margin', 'Tells you how many classes you can safely skip or must attend to keep 75%.'),
            _buildGuideBullet('☰ Top Menu', 'Tap the ☰ menu top-left to switch classes, batch groups, or test CR tools.'),
          ] else ...[
            _buildGuideBullet('✍️ 1-Tap Class Updates', 'Tap any class card below to mark cancelled, moved, or extra.'),
            _buildGuideBullet('📲 WhatsApp Broadcast', 'Instantly post formatted schedule updates to your class group.'),
            _buildGuideBullet('🔄 Switch to Student', 'Tap ⚡ CR mode in the top bar or sidebar to preview the student view.'),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Reopen anytime from ☰ sidebar',
                style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textStone500),
              ),
              const Spacer(),
              SizedBox(
                height: 30,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.burntOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    ref.read(hasSeenGuideProvider.notifier).markAsSeen();
                  },
                  child: Text(
                    'Got it!',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildGuideBullet(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppTheme.burntOrange, fontWeight: FontWeight.bold)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textStone700),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStrip(bool isOffline) {
    if (isOffline) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF78716C),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Last synced 8:40 AM • Offline mode',
                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textStone500),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F4),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.borderStone),
            ),
            child: Row(
              children: [
                const Icon(Icons.refresh_rounded, size: 12, color: AppTheme.textStone700),
                const SizedBox(width: 4),
                Text(
                  'Retry',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textStone700),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.sync_rounded, size: 14, color: AppTheme.burntOrange),
            const SizedBox(width: 6),
            Text(
              'Synced with Sumit (CR) • 2m ago',
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textStone500),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Live',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF065F46)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDayOverrideBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.swap_horiz_rounded, size: 16, color: Color(0xFF1E40AF)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Today follows Friday's timetable",
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'OVERRIDE',
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF1E40AF)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'SRM Dean Notice: Academic timetable swap due to upcoming long weekend.',
                  style: GoogleFonts.inter(fontSize: 11, color: Color(0xFF3B82F6), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHolidayBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFEDD5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wb_sunny_outlined, size: 18, color: AppTheme.burntOrange),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No classes today • National holiday',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textStone900),
                ),
                const SizedBox(height: 2),
                Text(
                  'Enjoy your well-earned break! The central library and campus sports complex remain open until 6:00 PM.',
                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textStone700, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderStone),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 18, color: AppTheme.textStone500),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "You're offline • Showing timetable saved...",
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textStone900),
                    ),
                    const Icon(Icons.close, size: 14, color: AppTheme.textStone400),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Real-time CR broadcast alerts paused until connection returns.',
                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textStone500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalHeroCard(bool isOffline, bool isDayOverride) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEA580C), Color(0xFFC2410C), Color(0xFF9A3412)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.burntOrange.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Inner capsule pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isOffline
                      ? 'NOW • Cached view • Ends 10:00 AM [25m left]'
                      : isDayOverride
                          ? 'NOW • Microprocessors • TP-402 ends 10:00 AM'
                          : 'NOW • Operating Systems • TP-101 ends 10:00 AM',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Subtitle UP NEXT
          Text(
            'UP NEXT • IN 1 HR 05 MIN',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 4),

          // Subject Title
          Text(
            isDayOverride ? 'Compiler Design' : 'DBMS Lab',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Time & Faculty Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_filled_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    '11:15 AM – 1:00 PM',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 13, color: AppTheme.burntOrange),
                    const SizedBox(width: 4),
                    Text(
                      isDayOverride ? 'TP-501 • Batch 1' : 'Lab 2 • Batch 1',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.burntOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isDayOverride ? 'Dr. Meera S.' : 'Ms. Priya Nair',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHolidayHeroCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderStone),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppTheme.peachTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.self_improvement_rounded, size: 36, color: AppTheme.burntOrange),
          ),
          const SizedBox(height: 14),
          Text(
            'Campus is quiet today',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textStone900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Next scheduled class is tomorrow,\nThursday 8 Oct at 9:00 AM (Operating Systems).',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textStone500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.peachBg,
              foregroundColor: AppTheme.burntOrange,
              elevation: 0,
              side: const BorderSide(color: AppTheme.peachTint),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.calendar_today_rounded, size: 16),
            label: Text(
              "View tomorrow's timetable",
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            onPressed: () {},
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {},
            child: Text(
              'Check holiday campus hours',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textStone500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCheckRow(BuildContext context, AttendanceState state) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month_outlined, size: 16, color: AppTheme.textStone700),
                const SizedBox(width: 6),
                Text(
                  'Attendance Check',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textStone900,
                  ),
                ),
              ],
            ),
            Text(
              'View All',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.burntOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildAttendanceMiniCard(
                subject: 'OS',
                sessions: '18/22',
                percent: '81.8%',
                badgeText: '+2 • Safe to miss',
                badgeBg: const Color(0xFFECFDF5),
                badgeTextCol: const Color(0xFF065F46),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildAttendanceMiniCard(
                subject: 'DBMS',
                sessions: '15/22',
                percent: '68.2%',
                badgeText: '⚠️ -6 • Need 6 classes',
                badgeBg: const Color(0xFFFEF2F2),
                badgeTextCol: const Color(0xFF991B1B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttendanceMiniCard({
    required String subject,
    required String sessions,
    required String percent,
    required String badgeText,
    required Color badgeBg,
    required Color badgeTextCol,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderStone),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subject,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textStone700),
              ),
              Text(
                sessions,
                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textStone400),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            percent,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textStone900,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeText,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: badgeTextCol,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineAttendanceCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderStone),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: AppTheme.peachTint, shape: BoxShape.circle),
                child: const Icon(Icons.analytics_outlined, size: 18, color: AppTheme.burntOrange),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Term Attendance (Cached)',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textStone900),
                  ),
                  Text(
                    '34 of 40 sessions attended',
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textStone500),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '85%',
                style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textStone900),
              ),
              Text(
                'Safe (>75%)',
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF065F46)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHolidayAttendanceOverview(AttendanceState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderStone),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.pie_chart_outline_rounded, size: 18, color: AppTheme.burntOrange),
                  const SizedBox(width: 8),
                  Text(
                    'Attendance Overview',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFF5F5F4), borderRadius: BorderRadius.circular(6)),
                child: Text('Term 5', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textStone500)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Aggregate Status', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textStone500)),
                    Text('77.4%', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textStone900)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.peachTint, borderRadius: BorderRadius.circular(8)),
                  child: Text('↗ +2.4% buffer', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.burntOrange)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(WidgetRef ref, String activeGroup) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => ref.read(activeGroupProvider.notifier).setGroup('B1'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.peachTint,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.burntOrange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_rounded, size: 14, color: AppTheme.burntOrange),
                  const SizedBox(width: 4),
                  Text(
                    'Batch 1 (My Batch)',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.burntOrange),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => ref.read(activeGroupProvider.notifier).setGroup('All'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderStone),
              ),
              child: Text(
                'All Batches',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textStone700),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderStone),
            ),
            child: Text(
              'Today Only',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textStone700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleHeader(bool isDayOverride, bool isOffline) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              isDayOverride ? 'Friday Schedule' : isOffline ? 'Wednesday Timeline' : 'Schedule',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textStone900),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFF5F5F4), borderRadius: BorderRadius.circular(6)),
              child: Text(
                isOffline ? '5 sessions cached' : '5 Classes',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textStone700),
              ),
            ),
          ],
        ),
        Text(
          'SRM Academia Slot 1',
          style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textStone500),
        ),
      ],
    );
  }

  Widget _buildScheduleTimeline(
    BuildContext context,
    WidgetRef ref,
    List<LiveClassItem> schedule,
    bool isEditor,
    bool isDayOverride,
    bool isOffline,
    String pageId,
  ) {
    return Column(
      children: [
        // 1. Operating Systems (NOW)
        _buildStitchClassCard(
          context: context,
          ref: ref,
          stripeColor: AppTheme.burntOrange,
          time: '9:00 AM – 10:00 AM',
          batch: 'Batch All',
          statusBadge: '• NOW',
          statusBg: AppTheme.peachBg,
          statusTextCol: AppTheme.burntOrange,
          subject: isDayOverride ? 'Microprocessors' : 'Operating Systems',
          room: isDayOverride ? 'TP-402' : 'TP-301',
          faculty: isDayOverride ? 'Prof. Sundaram' : 'Dr. Anita Verma',
          isEditor: isEditor,
          pageId: pageId,
        ),
        const SizedBox(height: 10),

        // 2. DBMS (Cancelled)
        _buildStitchClassCard(
          context: context,
          ref: ref,
          stripeColor: const Color(0xFFDC2626),
          time: '10:00 AM – 11:00 AM',
          batch: 'Batch All',
          statusBadge: 'Cancelled',
          statusBg: AppTheme.blushBg,
          statusTextCol: AppTheme.oxbloodText,
          subject: isDayOverride ? 'Software Engineering' : 'Database Management Systems',
          room: isDayOverride ? 'TP-302' : 'TP-406',
          faculty: isDayOverride ? 'Dr. Meera S.' : 'Prof. Rajesh K.',
          isCancelled: true,
          broadcastNotice: 'Sir on leave today — updated by Sumit (CR) • 8:42 AM',
          isEditor: isEditor,
          pageId: pageId,
        ),
        const SizedBox(height: 10),

        // 3. DBMS Lab (Scheduled)
        _buildStitchClassCard(
          context: context,
          ref: ref,
          stripeColor: const Color(0xFF10B981),
          time: '11:15 AM – 1:00 PM',
          batch: 'Batch 1',
          statusBadge: 'Scheduled',
          statusBg: const Color(0xFFECFDF5),
          statusTextCol: const Color(0xFF065F46),
          subject: isDayOverride ? 'Compiler Design Lab' : 'DBMS Lab',
          room: isDayOverride ? 'Lab 3' : 'Lab 2',
          faculty: isDayOverride ? 'Systems Complex' : 'Ms. Priya Nair',
          extraTag: '105 mins',
          isEditor: isEditor,
          pageId: pageId,
        ),
        const SizedBox(height: 10),

        // Lunch Break Row
        _buildBreakCard('Free Slot: 1:00 – 2:00 PM', 'Java Green & Library are open'),
        const SizedBox(height: 10),

        // 4. Computer Networks (Room Changed)
        _buildStitchClassCard(
          context: context,
          ref: ref,
          stripeColor: const Color(0xFF2563EB),
          time: '2:00 PM – 3:00 PM',
          batch: 'Batch All',
          statusBadge: '↗ Room Changed',
          statusBg: const Color(0xFFEFF6FF),
          statusTextCol: const Color(0xFF1E40AF),
          subject: isDayOverride ? 'Web Technologies' : 'Computer Networks',
          room: 'TP-310 ➔ TP-502',
          faculty: isDayOverride ? 'Prof. Ananya R.' : 'Dr. Kavita Rao',
          broadcastNotice: 'Updated by Sumit (CR) • 9:38 AM',
          isEditor: isEditor,
          pageId: pageId,
        ),
        const SizedBox(height: 10),

        // 5. Discrete Mathematics (Extra Class)
        _buildStitchClassCard(
          context: context,
          ref: ref,
          stripeColor: const Color(0xFF8B5CF6),
          time: '3:15 PM – 4:15 PM',
          batch: 'Batch All',
          statusBadge: 'Extra Class',
          statusBg: const Color(0xFFF5F3FF),
          statusTextCol: const Color(0xFF5B21B6),
          subject: 'Discrete Mathematics',
          room: 'TP-301',
          faculty: 'Prof. Arjun Mehta',
          isEditor: isEditor,
          pageId: pageId,
        ),
      ],
    );
  }

  Widget _buildStitchClassCard({
    required BuildContext context,
    required WidgetRef ref,
    required Color stripeColor,
    required String time,
    required String batch,
    required String statusBadge,
    required Color statusBg,
    required Color statusTextCol,
    required String subject,
    required String room,
    required String faculty,
    bool isCancelled = false,
    String? extraTag,
    String? broadcastNotice,
    required bool isEditor,
    required String pageId,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderStone),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Colored Stripe
              Container(width: 4, color: stripeColor),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time & Status Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                time,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textStone700,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.peachTint,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  batch,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.burntOrange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusBadge,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: statusTextCol,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Subject Title
                      Text(
                        subject,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isCancelled ? AppTheme.textStone400 : AppTheme.textStone900,
                          decoration: isCancelled ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Room & Faculty
                      Row(
                        children: [
                          const Icon(Icons.school_outlined, size: 14, color: AppTheme.textStone500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              faculty,
                              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textStone500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.meeting_room_outlined, size: 14, color: AppTheme.textStone500),
                          const SizedBox(width: 4),
                          Text(
                            room,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textStone700,
                            ),
                          ),
                        ],
                      ),

                      // Broadcast notice if present
                      if (broadcastNotice != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isCancelled ? AppTheme.blushBg : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCancelled ? const Color(0xFFFECACA) : const Color(0xFFBFDBFE),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isCancelled ? Icons.campaign_rounded : Icons.schedule_rounded,
                                size: 14,
                                color: isCancelled ? AppTheme.oxbloodText : const Color(0xFF1E40AF),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  broadcastNotice,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isCancelled ? AppTheme.oxbloodText : const Color(0xFF1E40AF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // CR Mode Quick Actions Row
                      if (isEditor) ...[
                        const Divider(height: 20, color: AppTheme.borderStone),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _showCRChangeStatusDialog(context, subject),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.edit_note_rounded, size: 16, color: AppTheme.burntOrange),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Change status',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.burntOrange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(width: 1, height: 16, color: AppTheme.borderStone),
                            Expanded(
                              child: InkWell(
                                onTap: () => _postToWhatsApp(subject, time, room),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.share_outlined, size: 14, color: AppTheme.burntOrange),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Post to WhatsApp',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.burntOrange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreakCard(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppTheme.peachTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_cafe_rounded, size: 16, color: AppTheme.burntOrange),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textStone900),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textStone500),
                  ),
                ],
              ),
            ],
          ),
          const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textStone400),
        ],
      ),
    );
  }

  Widget _buildHolidayCoffeeCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderStone),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFFF5F5F4), shape: BoxShape.circle),
                child: const Icon(Icons.local_cafe_rounded, size: 18, color: AppTheme.textStone700),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student Center Coffee Shop',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textStone900),
                  ),
                  Text(
                    'Holiday hours: 10:00 AM – 4:00 PM',
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textStone500),
                  ),
                ],
              ),
            ],
          ),
          const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textStone400),
        ],
      ),
    );
  }

  Widget _buildSkeletonScreen(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.canvasPaper,
      appBar: AppBar(
        title: Row(
          children: [
            Container(width: 26, height: 26, decoration: BoxDecoration(color: const Color(0xFFE7E5E4), borderRadius: BorderRadius.circular(8))),
            const SizedBox(width: 8),
            Container(width: 120, height: 16, decoration: BoxDecoration(color: const Color(0xFFE7E5E4), borderRadius: BorderRadius.circular(4))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined, size: 20, color: AppTheme.burntOrange),
            tooltip: 'Exit Skeleton State',
            onPressed: () {
              ref.read(stitchDemoStateProvider.notifier).setDemoState(StitchDemoState.normal);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Hero card skeleton
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFFE7E5E4),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 16),
            // Attendance row skeleton
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(color: const Color(0xFFE7E5E4), borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(color: const Color(0xFFE7E5E4), borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Filter skeleton
            Row(
              children: [
                Container(width: 110, height: 32, decoration: BoxDecoration(color: const Color(0xFFE7E5E4), borderRadius: BorderRadius.circular(16))),
                const SizedBox(width: 8),
                Container(width: 90, height: 32, decoration: BoxDecoration(color: const Color(0xFFE7E5E4), borderRadius: BorderRadius.circular(16))),
              ],
            ),
            const SizedBox(height: 16),
            // Schedule item skeletons
            ...List.generate(3, (i) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 90,
              decoration: BoxDecoration(color: const Color(0xFFE7E5E4), borderRadius: BorderRadius.circular(16)),
            )),
          ],
        ),
      ),
    );
  }

  void _showCRChangeStatusDialog(BuildContext context, String subject) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Quick Status: $subject', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            ListTile(
              leading: const Icon(Icons.cancel_outlined, color: Colors.red),
              title: const Text('Mark Cancelled (Sir on leave)'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Marked cancelled • Updated for 58 classmates')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz_rounded, color: Colors.blue),
              title: const Text('Move Room (e.g. TP-502)'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Room change saved • Broadcasted')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _postToWhatsApp(String subject, String time, String room) async {
    final text = '📢 $subject $time update: Room is $room. Check live schedule: https://rostra.ai/p/demo-class-101';
    final url = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      final webUrl = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }
}
