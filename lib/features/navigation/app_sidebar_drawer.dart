import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';
import '../onboarding/class_discovery_screen.dart';
import '../timetable/timetable_providers.dart';
import '../../services/update_checker_service.dart';

class AppSidebarDrawer extends ConsumerWidget {
  final int currentTabIndex;
  final ValueChanged<int> onSelectTab;
  final VoidCallback? onSwitchClass;
  final VoidCallback? onOpenGuide;

  const AppSidebarDrawer({
    super.key,
    required this.currentTabIndex,
    required this.onSelectTab,
    this.onSwitchClass,
    this.onOpenGuide,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(currentPageProvider);
    final isEditor = ref.watch(isEditorModeProvider);
    final activeGroup = ref.watch(activeGroupProvider);
    final storage = ref.watch(storageProvider);

    final classTitle = page != null ? '${page.department} ${page.year} • ${page.section}' : 'CSE 3rd Year • Sec A';
    final institution = page?.college ?? 'SRM Institute';
    const followerCount = 58;

    return Drawer(
      backgroundColor: AppTheme.canvasPaper,
      child: SafeArea(
        child: Column(
          children: [
            // Header: Brand & Class Info
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppTheme.stoneBorder)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Brand Row
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.flameOrange, AppTheme.burntOrange],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Icon(Icons.notifications_active_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConstants.appName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textStone900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Live Class Timetable',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: AppTheme.textStone500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Close Drawer button
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textStone400),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Active Class Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.canvasPaper,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.stoneBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                classTitle,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textStone900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.peachTint,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                activeGroup,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.burntOrange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$institution • $followerCount students',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.textStone500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 1-Tap Role Switcher Toggle
                  InkWell(
                    onTap: () {
                      ref.read(isEditorModeProvider.notifier).toggle();
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isEditor ? AppTheme.peachBg : const Color(0xFFF5F5F4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isEditor ? AppTheme.burntOrange : AppTheme.stoneBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isEditor ? Icons.bolt_rounded : Icons.school_rounded,
                            size: 16,
                            color: isEditor ? AppTheme.burntOrange : AppTheme.textStone700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEditor ? '⚡ Class Rep Mode Active' : '🎓 Student Mode Active',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: isEditor ? AppTheme.burntOrange : AppTheme.textStone900,
                                  ),
                                ),
                                Text(
                                  isEditor ? 'Tap to switch to Student view' : 'Tap to switch to CR admin tools',
                                  style: GoogleFonts.inter(
                                    fontSize: 9.5,
                                    color: AppTheme.textStone500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isEditor ? AppTheme.burntOrange : AppTheme.textStone400,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'SWITCH',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                children: [
                  _buildSectionHeader('MAIN SCREENS'),
                  _buildNavItem(
                    context: context,
                    icon: Icons.calendar_today_rounded,
                    label: 'Today’s Live Feed',
                    subtitle: 'Class changes, cancellations & rooms',
                    isSelected: currentTabIndex == 0,
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab(0);
                    },
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.calendar_view_week_rounded,
                    label: 'Weekly Timetable',
                    subtitle: 'Mon–Sat schedule & room matrix',
                    isSelected: currentTabIndex == 1,
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab(1);
                    },
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.fact_check_rounded,
                    label: 'Attendance Calculator',
                    subtitle: 'Safe margin (how many you can miss)',
                    isSelected: currentTabIndex == 2,
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab(2);
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: AppTheme.stoneBorder, height: 1),
                  ),

                  _buildSectionHeader('CLASS MANAGEMENT'),
                  _buildNavItem(
                    context: context,
                    icon: Icons.share_rounded,
                    label: 'Share Class Link',
                    subtitle: 'Invite classmates to follow timetable',
                    onTap: () {
                      Navigator.pop(context);
                      _showShareModal(context, classTitle, page?.id ?? 'demo-class-101');
                    },
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.swap_horiz_rounded,
                    label: 'Switch / Join Class',
                    subtitle: 'Enter another class code or section',
                    onTap: () {
                      Navigator.pop(context);
                      if (onSwitchClass != null) {
                        onSwitchClass!();
                      } else {
                        _showSwitchClassDialog(context, ref);
                      }
                    },
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.group_work_outlined,
                    label: 'Batch Filter ($activeGroup)',
                    subtitle: 'Switch between All, Batch 1, Batch 2',
                    onTap: () {
                      Navigator.pop(context);
                      _showBatchSelector(context, ref, activeGroup);
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: AppTheme.stoneBorder, height: 1),
                  ),

                  _buildSectionHeader('HELP & SETTINGS'),
                  _buildNavItem(
                    context: context,
                    icon: Icons.lightbulb_outline_rounded,
                    label: 'How RostraAI Works',
                    subtitle: 'Interactive guide & feature tour',
                    onTap: () {
                      Navigator.pop(context);
                      if (onOpenGuide != null) {
                        onOpenGuide!();
                      } else {
                        _showGuideModal(context, isEditor);
                      }
                    },
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.tune_rounded,
                    label: 'Attendance Target',
                    subtitle: 'Currently set to ${storage.getAttendanceTarget()}%',
                    onTap: () {
                      Navigator.pop(context);
                      _showAttendanceTargetDialog(context, ref);
                    },
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.system_update_rounded,
                    label: 'Check for Updates',
                    subtitle: 'v${AppConstants.appVersion}',
                    onTap: () async {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Checking GitHub for new updates...'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      final info = await UpdateCheckerService.checkForUpdate();
                      if (context.mounted) {
                        if (info != null && info.hasUpdate) {
                          UpdateCheckerService.showUpdateDialog(context, info);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('You are on the latest version (v${AppConstants.appVersion})!'),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const Divider(color: AppTheme.stoneBorder, height: 16),
                  _buildSectionHeader('ACCOUNT'),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    visualDensity: const VisualDensity(vertical: -2),
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.peachTint,
                      backgroundImage: storage.getUserPhotoUrl() != null ? NetworkImage(storage.getUserPhotoUrl()!) : null,
                      child: storage.getUserPhotoUrl() == null
                          ? Text(
                              (storage.getUserName() ?? 'S').substring(0, 1).toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.burntOrange,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      storage.getUserName() ?? 'Student Account',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textStone900),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      storage.getUserEmail() ?? 'Signed in',
                      style: GoogleFonts.inter(fontSize: 10.5, color: AppTheme.textStone500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFDC2626)),
                      tooltip: 'Sign Out',
                      onPressed: () async {
                        Navigator.pop(context);
                        await ref.read(authProvider.notifier).signOut();
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.stoneBorder)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 14, color: AppTheme.textStone400),
                  const SizedBox(width: 6),
                  Text(
                    'DPDP Act Compliant (18+)',
                    style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textStone400),
                  ),
                  const Spacer(),
                  Text(
                    'v${AppConstants.appVersion}',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textStone400),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: AppTheme.textStone400,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.peachTint : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected ? Border.all(color: AppTheme.burntOrange.withValues(alpha: 0.3)) : null,
      ),
      child: ListTile(
        visualDensity: const VisualDensity(vertical: -2),
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(
          icon,
          size: 20,
          color: isSelected ? AppTheme.burntOrange : AppTheme.textStone700,
        ),
        title: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? AppTheme.burntOrange : AppTheme.textStone900,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            color: AppTheme.textStone500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: onTap,
      ),
    );
  }

  // --- Modal Helpers ---

  static void _showShareModal(BuildContext context, String classTitle, String pageId) {
    final link = 'https://rostra.ai/p/$pageId';
    final shareMsg = 'Check out our live class timetable for $classTitle on RostraAI:\n$link';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.peachTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.share_rounded, color: AppTheme.burntOrange, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Share Class Timetable',
                  style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Anyone with this link can view real-time class changes without installing the app or creating an account.',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textStone500, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.stoneBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, size: 16, color: AppTheme.textStone400),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      link,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textStone700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18, color: AppTheme.burntOrange),
                    tooltip: 'Copy link',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: link));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Class link copied to clipboard!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  'Share to Class WhatsApp Group',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final uri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(shareMsg)}');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    Clipboard.setData(ClipboardData(text: shareMsg));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('WhatsApp message copied to clipboard!')),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showSwitchClassDialog(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const ClassDiscoveryScreen()),
    );
  }

  static void _showBatchSelector(BuildContext context, WidgetRef ref, String current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Your Batch / Lab Group',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...['All', 'B1', 'B2'].map(
              (group) => ListTile(
                leading: Icon(
                  group == current ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: group == current ? AppTheme.burntOrange : AppTheme.textStone400,
                  size: 20,
                ),
                title: Text(
                  group == 'All' ? 'All Classes (Common lectures + labs)' : 'Batch $group (Specific lab group only)',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  ref.read(activeGroupProvider.notifier).setGroup(group);
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showAttendanceTargetDialog(BuildContext context, WidgetRef ref) {
    final storage = ref.read(storageProvider);
    int current = storage.getAttendanceTarget();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            'Attendance Minimum Target',
            style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Set the percentage required by your college or university to calculate your safe margin:',
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textStone500),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded, color: AppTheme.burntOrange),
                    onPressed: current > 50 ? () => setDialogState(() => current -= 5) : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.peachTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$current%',
                      style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.burntOrange),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.burntOrange),
                    onPressed: current < 95 ? () => setDialogState(() => current += 5) : null,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.burntOrange,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await storage.setAttendanceTarget(current);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save Target'),
            ),
          ],
        ),
      ),
    );
  }

  static void _showGuideModal(BuildContext context, bool isEditor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: AppTheme.textStone300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.peachTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.lightbulb_rounded, color: AppTheme.burntOrange, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How RostraAI Works',
                        style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Never reach an empty room again',
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textStone500),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildGuideStep(
                number: '1',
                title: 'Live Today Feed & Status Indicators',
                desc: 'Green = On time in normal room.\nRed = Class cancelled by CR.\nAmber = Room moved or time shifted.',
              ),
              _buildGuideStep(
                number: '2',
                title: 'Attendance Margin (Whole Numbers)',
                desc: 'No confusing percentages! We show whole numbers: "Can miss 2 more" in green, or "Attend 4 in a row" in red if you are below 75%.',
              ),
              _buildGuideStep(
                number: '3',
                title: '1-Tap WhatsApp Broadcast (CR Tool)',
                desc: 'Class Representatives can tap any class to update status and instantly send a pre-formatted message to the class WhatsApp group in 1 tap.',
              ),
              _buildGuideStep(
                number: '4',
                title: 'Zero-Account Follow',
                desc: 'Share your class link or code with classmates. Anyone can view live updates on web or app without signing up.',
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.burntOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Got it!'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildGuideStep({
    required String number,
    required String title,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppTheme.peachTint,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.burntOrange.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.burntOrange,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textStone900),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textStone600, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
