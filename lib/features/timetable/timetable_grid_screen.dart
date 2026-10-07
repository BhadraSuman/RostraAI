import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../models/timetable_models.dart';
import 'add_slot_sheet.dart';
import 'timetable_providers.dart';

class TimetableGridScreen extends ConsumerStatefulWidget {
  const TimetableGridScreen({super.key});

  @override
  ConsumerState<TimetableGridScreen> createState() => _TimetableGridScreenState();
}

class _TimetableGridScreenState extends ConsumerState<TimetableGridScreen> {
  int _selectedDayIndex = 2; // Default to WED (index 2) as in Stitch
  String _selectedBatch = 'All Batches';

  final List<Map<String, String>> _daysInfo = [
    {'day': 'MONDAY', 'short': 'MON', 'date': '05'},
    {'day': 'TUESDAY', 'short': 'TUE', 'date': '06'},
    {'day': 'WEDNESDAY', 'short': 'WED', 'date': '07', 'today': 'true'},
    {'day': 'THURSDAY', 'short': 'THU', 'date': '08'},
    {'day': 'FRIDAY', 'short': 'FRI', 'date': '09'},
    {'day': 'SATURDAY', 'short': 'SAT', 'date': '10'},
  ];

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(timetableEntriesProvider);
    final isEditor = ref.watch(isEditorModeProvider);
    final currentDay = _daysInfo[_selectedDayIndex]['day']!;
    final currentDayShort = _daysInfo[_selectedDayIndex]['short']!;

    // Filter day entries
    final dayEntries = entries.where((e) {
      if (e.day != currentDay) return false;
      if (_selectedBatch == 'All Batches') return true;
      if (_selectedBatch == 'Batch 1') return e.group == 'All' || e.group == 'B1' || e.group == 'Batch 1';
      if (_selectedBatch == 'Batch 2') return e.group == 'All' || e.group == 'B2' || e.group == 'Batch 2';
      return true;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

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
                      'Timetable',
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cohort Title Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'CSE 3rd Year • Sec A',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textStone900,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.flameOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Weekly Schedule • Odd Sem 2024',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textStone500),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.search_rounded, size: 22, color: AppTheme.textStone700),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_month_outlined, size: 22, color: AppTheme.textStone700),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // CR Sync Mode Banner if in Editor Mode
            if (isEditor) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.peachBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.peachTint),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sensors_rounded, size: 16, color: AppTheme.burntOrange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'CR Sync Mode • Changes broadcast instantly',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.burntOrange,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.burntOrange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Live',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Day Selector Tabs (MON 05, TUE 06, WED 07 TODAY, etc.)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_daysInfo.length, (idx) {
                final dayData = _daysInfo[idx];
                final isSelected = _selectedDayIndex == idx;
                final isToday = dayData['today'] == 'true';

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedDayIndex = idx);
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: idx < _daysInfo.length - 1 ? 6 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.peachTint : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppTheme.burntOrange : AppTheme.borderStone,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            dayData['short']!,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? AppTheme.burntOrange : AppTheme.textStone500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayData['date']!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? AppTheme.burntOrange : AppTheme.textStone900,
                                ),
                              ),
                              if (isToday) ...[
                                const SizedBox(width: 3),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.burntOrange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (isToday)
                            Text(
                              'TODAY',
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.burntOrange,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),

            // Audience Batch Filter Bar
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F4),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: ['Batch 1', 'Batch 2', 'All Batches'].map((b) {
                  final isSel = _selectedBatch == b;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedBatch = b),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isSel
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            b,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                              color: isSel ? AppTheme.textStone900 : AppTheme.textStone500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Schedule Day Info Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '${currentDay[0]}${currentDay.substring(1).toLowerCase()} Schedule',
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
                        '${dayEntries.length} slots',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textStone700),
                      ),
                    ),
                  ],
                ),
                Text(
                  '3h 45m Lecture • 1h 45m Lab',
                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textStone500),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Timeline Class List
            if (dayEntries.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderStone),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.event_available_rounded, size: 40, color: AppTheme.textStone400),
                    const SizedBox(height: 10),
                    Text(
                      'No classes scheduled for $currentDayShort',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textStone700),
                    ),
                  ],
                ),
              )
            else
              ...List.generate(dayEntries.length, (idx) {
                final entry = dayEntries[idx];
                final isLast = idx == dayEntries.length - 1;

                // Insert breaks for sample realism matching Stitch
                Widget? breakWidget;
                if (idx == 1) {
                  breakWidget = _buildTransitBreak('Transit & Tea Break', '15 min');
                } else if (idx == 2) {
                  breakWidget = _buildLunchBreak('Campus Lunch Interval', '1:00 PM – 2:00 PM', '60 mins');
                }

                return Column(
                  children: [
                    _buildTimetableSlotCard(context, entry, isEditor, currentDay),
                    if (breakWidget != null) ...[
                      const SizedBox(height: 10),
                      breakWidget,
                      const SizedBox(height: 10),
                    ] else if (!isLast) ...[
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              }),

            const SizedBox(height: 24),

            // Follower Share Card or CR Mode FAB
            if (!isEditor) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderStone),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.peachTint,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.shield_outlined, size: 18, color: AppTheme.burntOrange),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CR Sync: Sumit Sharma',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textStone900),
                              ),
                              Text(
                                'Verified today at 09:30 AM',
                                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textStone500),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                              const SizedBox(width: 4),
                              Text(
                                'Live',
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF065F46)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.peachBg,
                        foregroundColor: AppTheme.burntOrange,
                        elevation: 0,
                        side: const BorderSide(color: AppTheme.peachTint),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size.fromHeight(44),
                      ),
                      onPressed: () => _shareScheduleOnWhatsApp(currentDay, dayEntries),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.share_outlined, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            "Share Today's Schedule on WhatsApp",
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Floating / Sticky Add Class Slot Button
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.burntOrange,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppTheme.burntOrange.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(
                    'Add class slot',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () {
                    AddSlotSheet.show(
                      context,
                      currentDay: currentDay,
                      onSave: (newEntry) {
                        ref.read(timetableEntriesProvider.notifier).addEntry(
                              day: newEntry.day,
                              startTime: newEntry.startTime,
                              endTime: newEntry.endTime,
                              subject: newEntry.subject,
                              room: newEntry.room,
                              teacher: newEntry.teacher,
                              group: newEntry.group,
                              courseCode: newEntry.courseCode,
                            );
                      },
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildTimetableSlotCard(
    BuildContext context,
    TimetableEntry entry,
    bool isEditor,
    String currentDay,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Time Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.peachTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  entry.startTime,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.burntOrange,
                  ),
                ),
                Text(
                  entry.endTime,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.deepOrange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Details column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.courseCode != null && entry.courseCode!.isNotEmpty) ...[
                  Text(
                    '${entry.courseCode} • ${entry.subject.toLowerCase().contains("lab") ? "PRACTICAL LAB" : "THEORY"}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.burntOrange,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  entry.subject,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textStone900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.meeting_room_outlined, size: 14, color: AppTheme.textStone500),
                    const SizedBox(width: 4),
                    Text(
                      entry.room,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textStone700),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.school_outlined, size: 14, color: AppTheme.textStone500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        entry.teacher,
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textStone500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions if in editor mode
          if (isEditor) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.textStone500),
              onPressed: () {
                AddSlotSheet.show(
                  context,
                  currentDay: currentDay,
                  existing: entry,
                  onSave: (updated) {
                    ref.read(timetableEntriesProvider.notifier).updateEntry(updated);
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.textStone400),
              onPressed: () {
                ref.read(timetableEntriesProvider.notifier).removeEntry(entry.id);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransitBreak(String title, String duration) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_walk_rounded, size: 16, color: AppTheme.textStone500),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textStone700),
              ),
            ],
          ),
          Text(
            duration,
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textStone500),
          ),
        ],
      ),
    );
  }

  Widget _buildLunchBreak(String title, String time, String duration) {
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
              const Icon(Icons.restaurant_rounded, size: 16, color: AppTheme.burntOrange),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textStone900),
              ),
            ],
          ),
          Text(
            '$time ($duration)',
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textStone500),
          ),
        ],
      ),
    );
  }

  void _shareScheduleOnWhatsApp(String day, List<TimetableEntry> entries) async {
    final lines = [
      '📅 Schedule for $day — CSE 3rd Year Sec A',
      '',
    ];
    for (final e in entries) {
      lines.add('• ${e.startTime} - ${e.endTime}: ${e.subject} (${e.room}, ${e.teacher})');
    }
    lines.add('');
    lines.add('Live updates: https://rostra.ai/p/demo-class-101');

    final text = lines.join('\n');
    final url = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      final webUrl = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }
}
