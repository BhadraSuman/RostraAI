import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../timetable/timetable_providers.dart';
import 'attendance_calculator.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(attendanceProvider);
    final isEditor = ref.watch(isEditorModeProvider);
    final notifier = ref.read(attendanceProvider.notifier);

    // Calculate totals across records
    int totalAttended = 0;
    int totalHeld = 0;
    for (final r in state.records.values) {
      totalAttended += r.attended;
      totalHeld += r.held;
    }
    final aggregatePercent = totalHeld > 0 ? (totalAttended / totalHeld * 100) : 0.0;
    final overallMargin = calculateAttendanceMargin(totalAttended, totalHeld, state.targetPercent);

    return Scaffold(
      backgroundColor: AppTheme.canvasPaper,
      appBar: AppBar(
        titleSpacing: 16,
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
                      'Attendance',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textStone900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.peachTint,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isEditor ? '⚡ CR' : 'STUDENT',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.burntOrange,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'SRM Institute • 58 following',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.textStone500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.textStone700),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () {
                ref.read(isEditorModeProvider.notifier).toggle();
              },
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF7C2D12),
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Page Title Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Attendance Tracker',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textStone900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Sem VI',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textStone700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.burntOrange),
                        const SizedBox(width: 3),
                        Text(
                          '${state.targetPercent}% Minimum Campus Requirement',
                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textStone500),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline_rounded, size: 20, color: AppTheme.textStone500),
                  onPressed: () => _showTargetDialog(context, state.targetPercent, notifier),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Overall Aggregate Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderStone),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'OVERALL AGGREGATE',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: AppTheme.textStone500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.peachTint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppTheme.burntOrange, shape: BoxShape.circle)),
                            const SizedBox(width: 5),
                            Text(
                              overallMargin >= 0
                                  ? '+$overallMargin Overall Safety Margin'
                                  : '-${overallMargin.abs()} Deficit Margin',
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
                  const SizedBox(height: 10),

                  // Big Percentage
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${aggregatePercent.toStringAsFixed(1)}%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textStone900,
                          ),
                        ),
                        TextSpan(
                          text: ' / 100%',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textStone400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Progress Bar with Cutoff Indicator
                  _buildCutoffProgressBar(aggregatePercent, state.targetPercent.toDouble()),
                  const SizedBox(height: 8),

                  // Cutoff row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('0%', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textStone400)),
                      Text('Campus Cutoff: ${state.targetPercent}%', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textStone500)),
                      Text('100%', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textStone400)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3 Stat Boxes
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricBox('Attended', '$totalAttended', AppTheme.textStone900),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricBox('Conducted', '$totalHeld', AppTheme.textStone900),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricBox('Remaining', '32', AppTheme.burntOrange),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Course Breakdown Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Course Breakdown',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textStone900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${state.records.length} Subjects',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textStone700),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Updated today, 8:45 AM',
                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textStone500),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Subject Cards List
            ...state.records.values.map((record) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSubjectCard(context, record, state.targetPercent, notifier),
              );
            }),
            const SizedBox(height: 12),

            // Simulate Upcoming Absences / Bunks Button
            InkWell(
              onTap: () => _showAbsenceSimulator(context, state),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderStone),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.event_busy_outlined, size: 18, color: AppTheme.burntOrange),
                    const SizedBox(width: 8),
                    Text(
                      'Simulate Upcoming Absences / Bunks',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textStone900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Footer note
            Center(
              child: Text(
                'Calculations update automatically based on official SRM faculty logs.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textStone400),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCutoffProgressBar(double percent, double cutoff) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final cutoffX = (cutoff / 100.0) * totalWidth;
        final fillWidth = ((percent / 100.0).clamp(0.0, 1.0)) * totalWidth;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Track
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F4),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            // Fill
            Container(
              height: 10,
              width: fillWidth,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.flameOrange, AppTheme.burntOrange],
                ),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            // Cutoff indicator line
            Positioned(
              left: cutoffX - 1,
              top: -4,
              bottom: -4,
              child: Container(
                width: 2,
                color: AppTheme.textStone700,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricBox(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textStone500),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(
    BuildContext context,
    AttendanceRecord record,
    int targetPercent,
    AttendanceNotifier notifier,
  ) {
    final margin = calculateAttendanceMargin(record.attended, record.held, targetPercent);
    final isSafe = margin >= 0;
    final percent = record.percentage;
    final isDeficit = !isSafe;

    Color badgeBg;
    Color badgeText;
    String badgeLabel;
    String marginText;

    if (percent >= 90) {
      badgeBg = const Color(0xFFECFDF5);
      badgeText = const Color(0xFF065F46);
      badgeLabel = 'EXEMPLARY';
      marginText = '+$margin • Safe';
    } else if (isSafe && margin <= 1) {
      badgeBg = const Color(0xFFFFFBEB);
      badgeText = const Color(0xFF92400E);
      badgeLabel = 'TIGHT SAFE';
      marginText = '+$margin • Can miss $margin more';
    } else if (isSafe) {
      badgeBg = AppTheme.peachTint;
      badgeText = AppTheme.burntOrange;
      badgeLabel = 'SAFE';
      marginText = '+$margin • Can miss $margin more';
    } else {
      badgeBg = AppTheme.blushBg;
      badgeText = AppTheme.oxbloodText;
      badgeLabel = 'DEFICIT';
      marginText = '$margin • Attend ${margin.abs()} in a row';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDeficit ? const Color(0xFFFECACA) : AppTheme.borderStone,
          width: isDeficit ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Left Stripe for Deficit
          if (isDeficit)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Title + Percentage
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  record.subject,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textStone900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _getSubjectCode(record.subject),
                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textStone500),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${record.attended} of ${record.held} sessions attended',
                            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textStone500),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${percent.toStringAsFixed(1)}%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDeficit ? const Color(0xFFDC2626) : AppTheme.textStone900,
                          ),
                        ),
                        Text(
                          isDeficit ? 'Below $targetPercent%' : 'Current',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDeficit ? const Color(0xFFDC2626) : AppTheme.textStone500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Margin Badge Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isDeficit ? Icons.warning_amber_rounded : Icons.schedule_rounded,
                            size: 14,
                            color: badgeText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            marginText,
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: badgeText),
                          ),
                        ],
                      ),
                      Text(
                        badgeLabel,
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: badgeText, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: record.held > 0 ? (record.attended / record.held).clamp(0.0, 1.0) : 1.0,
                    backgroundColor: const Color(0xFFF5F5F4),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDeficit ? const Color(0xFFDC2626) : AppTheme.burntOrange,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 10),

                // Footer Note & Interactive Check-in
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _getSubjectNextFooter(record.subject),
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textStone500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        InkWell(
                          onTap: () => notifier.markAttended(record.subject),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.add, size: 16, color: Color(0xFF065F46)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => notifier.markMissed(record.subject),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.remove, size: 16, color: Color(0xFF991B1B)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getSubjectCode(String subject) {
    final lower = subject.toLowerCase();
    if (lower.contains('operating')) return 'CS301';
    if (lower.contains('data') || lower.contains('dbms') && !lower.contains('lab')) return 'CS304';
    if (lower.contains('lab')) return 'CS304L';
    if (lower.contains('network')) return 'CS302';
    if (lower.contains('discrete') || lower.contains('math')) return 'MA203';
    return 'SUB';
  }

  String _getSubjectNextFooter(String subject) {
    final lower = subject.toLowerCase();
    if (lower.contains('operating')) return '• Today at 11:30 AM (Ongoing)  Hall LH-302';
    if (lower.contains('data') || lower.contains('dbms') && !lower.contains('lab')) {
      return '1 cancelled class today does not affect req. Next: Fri';
    }
    if (lower.contains('network')) return 'Next: Tomorrow, 10:15 AM  Hall TP-401';
    if (lower.contains('discrete') || lower.contains('math')) return 'Next: Thursday, 1:00 PM  Hall 4th-105';
    if (lower.contains('lab')) return 'Next: Friday, 2:00 PM  CS Lab 04';
    return 'Official SRM faculty log verified';
  }

  void _showTargetDialog(BuildContext context, int current, AttendanceNotifier notifier) {
    int selected = current;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dCtx, setDialogState) {
            return AlertDialog(
              title: Text(
                'Campus Cutoff Target',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$selected%',
                    style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.burntOrange),
                  ),
                  Slider(
                    value: selected.toDouble(),
                    min: 50,
                    max: 95,
                    divisions: 9,
                    activeColor: AppTheme.burntOrange,
                    label: '$selected%',
                    onChanged: (val) => setDialogState(() => selected = val.toInt()),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    notifier.setTargetPercent(selected);
                    Navigator.pop(dCtx);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAbsenceSimulator(BuildContext context, AttendanceState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Simulate Upcoming Absences / Bunks',
                style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'See the exact impact on your safety margin if you miss classes this week.',
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textStone500),
              ),
              const SizedBox(height: 16),
              ...state.records.values.take(3).map((r) {
                final margin = calculateAttendanceMargin(r.attended, r.held + 1, state.targetPercent);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(r.subject, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text('If you miss 1 class', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textStone500)),
                  trailing: Text(
                    margin >= 0 ? 'Margin: +$margin' : 'Deficit: $margin',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: margin >= 0 ? const Color(0xFF065F46) : const Color(0xFFDC2626),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close Simulator'),
              ),
            ],
          ),
        );
      },
    );
  }
}
