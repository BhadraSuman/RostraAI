import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ist_clock.dart';
import '../../models/timetable_models.dart';
import '../attendance/attendance_calculator.dart';
import '../timetable/timetable_providers.dart';

class TodayViewScreen extends ConsumerWidget {
  const TodayViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(currentPageProvider);
    final todaySchedule = ref.watch(todayScheduleProvider);
    final activeGroup = ref.watch(activeGroupProvider);
    final isEditor = ref.watch(isEditorModeProvider);
    final attendanceState = ref.watch(attendanceProvider);
    final todayOverride = ref.watch(todayOverrideProvider);

    final todayDate = IstClock.todayDateString();
    final weekday = IstClock.weekdayName();

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: isEditor ? () => _showEditPageDialog(context, ref, page) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    page?.title ?? 'Class Timetable',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  if (isEditor) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.edit, size: 14, color: AppTheme.primaryBlue),
                  ],
                ],
              ),
              Text(
                '$weekday, $todayDate',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        actions: [
          // Day Override Action for CR
          if (isEditor)
            IconButton(
              icon: const Icon(Icons.rule_folder_outlined),
              tooltip: 'Set Day Override',
              onPressed: () => _showDayOverrideDialog(context, ref, todayOverride),
            ),

          // CR Mode Switcher chip
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: Icon(
                isEditor ? Icons.edit_note : Icons.visibility,
                size: 16,
                color: isEditor ? Colors.white : AppTheme.primaryBlue,
              ),
              label: Text(
                isEditor ? 'CR Mode' : 'Student Mode',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isEditor ? Colors.white : AppTheme.primaryBlue,
                ),
              ),
              selected: isEditor,
              selectedColor: AppTheme.primaryBlue,
              backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
              onSelected: (_) {
                ref.read(isEditorModeProvider.notifier).toggle();
              },
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Day Override Banner if active
          if (todayOverride != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: todayOverride.isNoClasses ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: todayOverride.isNoClasses ? const Color(0xFFFCA5A5) : const Color(0xFFFCD34D),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      todayOverride.isNoClasses ? Icons.event_busy : Icons.swap_horiz,
                      color: todayOverride.isNoClasses ? Colors.red : Colors.amber.shade800,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            todayOverride.isNoClasses
                                ? 'No Classes Today'
                                : 'Timetable Override: Follows ${todayOverride.followsWeekday} Schedule',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: todayOverride.isNoClasses ? Colors.red.shade900 : Colors.amber.shade900,
                            ),
                          ),
                          if (todayOverride.note != null && todayOverride.note!.isNotEmpty)
                            Text(
                              todayOverride.note!,
                              style: TextStyle(
                                fontSize: 12,
                                color: todayOverride.isNoClasses ? Colors.red.shade800 : Colors.amber.shade800,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isEditor)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          ref.read(todayOverrideProvider.notifier).clearOverride();
                        },
                      ),
                  ],
                ),
              ),
            ),

          // Group Selection Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  const Text(
                    'Group: ',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 8),
                  Wrap(
                    spacing: 8,
                    children: (page?.availableGroups ?? ['All', 'B1', 'B2']).map((grp) {
                      final isSelected = activeGroup == grp;
                      return ChoiceChip(
                        label: Text(grp),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppTheme.primaryBlue : Colors.black87,
                        ),
                        onSelected: (_) {
                          ref.read(activeGroupProvider.notifier).setGroup(grp);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Attendance Quick Margin Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _buildAttendanceQuickBanner(attendanceState),
            ),
          ),

          // Schedule List
          todaySchedule.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.weekend_outlined, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          todayOverride?.isNoClasses ?? false
                              ? 'All classes cancelled today by day override'
                              : 'No classes scheduled for $weekday',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enjoy your free time!',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = todaySchedule[index];
                        return _buildClassCard(context, ref, item, isEditor, page?.id ?? 'demo-class-101');
                      },
                      childCount: todaySchedule.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildAttendanceQuickBanner(AttendanceState attendanceState) {
    if (attendanceState.records.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.analytics_outlined, color: AppTheme.primaryBlue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Attendance Margin (${AppConstants.defaultAttendanceTargetPercent}% Target)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatQuickMarginText(attendanceState),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatQuickMarginText(AttendanceState state) {
    final summaries = <String>[];
    for (final entry in state.records.values) {
      final margin = calculateAttendanceMargin(entry.attended, entry.held, state.targetPercent);
      final shortSubject = entry.subject.length > 8 ? '${entry.subject.substring(0, 7)}..' : entry.subject;
      if (margin >= 0) {
        summaries.add('$shortSubject: can miss $margin');
      } else {
        summaries.add('$shortSubject: attend ${margin.abs()} in a row');
      }
    }
    return summaries.take(2).join(' • ');
  }

  Widget _buildClassCard(
    BuildContext context,
    WidgetRef ref,
    LiveClassItem item,
    bool isEditor,
    String pageId,
  ) {
    final entry = item.entry;
    final status = item.status;
    final isCancelled = item.isCancelled;

    Color badgeColor;
    String badgeText;

    if (isCancelled) {
      badgeColor = AppTheme.statusCancelled;
      badgeText = 'Cancelled';
    } else if (item.isRoomMoved) {
      badgeColor = AppTheme.statusMoved;
      badgeText = 'Room Changed';
    } else if (item.isTimeMoved) {
      badgeColor = AppTheme.statusMoved;
      badgeText = 'Time Moved';
    } else if (item.isExtraClass) {
      badgeColor = AppTheme.statusExtra;
      badgeText = 'Extra Class';
    } else {
      badgeColor = AppTheme.statusNormal;
      badgeText = 'Scheduled';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isEditor
            ? () {
                _showStatusBottomSheet(context, ref, item, pageId);
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time & Status Badge Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        '${item.effectiveStartTime} - ${item.effectiveEndTime}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isCancelled ? Colors.grey : const Color(0xFF0F172A),
                          decoration: isCancelled ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (entry.group != 'All') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            entry.group,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Subject Title
              Text(
                entry.subject,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isCancelled ? Colors.grey : const Color(0xFF0F172A),
                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(height: 6),

              // Room & Teacher Details
              Row(
                children: [
                  Icon(Icons.meeting_room_outlined, size: 15, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    item.effectiveRoom,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: item.isRoomMoved ? FontWeight.bold : FontWeight.normal,
                      color: item.isRoomMoved ? AppTheme.statusMoved : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Icon(Icons.person_outline_rounded, size: 15, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      entry.teacher,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Status Note if available
              if (status?.note != null && status!.note!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 15, color: AppTheme.statusCancelled),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${status.note} — by ${status.updatedByName}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // CR Tap to change hint
              if (isEditor) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Tap to change status / post to WhatsApp',
                    style: TextStyle(fontSize: 11, color: AppTheme.primaryBlue.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusBottomSheet(
    BuildContext context,
    WidgetRef ref,
    LiveClassItem item,
    String pageId,
  ) {
    final noteController = TextEditingController(text: item.status?.note ?? '');
    final roomController = TextEditingController(text: item.status?.updatedRoom ?? item.entry.room);
    ClassStatusType selectedStatus = item.status?.status ?? ClassStatusType.normal;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Update: ${item.entry.subject}',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Status Choices
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ClassStatusType.values.map((st) {
                        final isSel = selectedStatus == st;
                        return ChoiceChip(
                          label: Text(st.displayName),
                          selected: isSel,
                          selectedColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
                          onSelected: (_) {
                            setModalState(() => selectedStatus = st);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    if (selectedStatus == ClassStatusType.roomMoved) ...[
                      TextField(
                        controller: roomController,
                        decoration: const InputDecoration(labelText: 'New Room Number'),
                      ),
                      const SizedBox(height: 12),
                    ],

                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Optional note (e.g. Sir on leave / Lab relocated)',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Update Status Button
                    ElevatedButton(
                      onPressed: () async {
                        await ref.read(todayStatusesProvider.notifier).setStatus(
                              entryId: item.entry.id,
                              status: selectedStatus,
                              note: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
                              updatedRoom: selectedStatus == ClassStatusType.roomMoved ? roomController.text.trim() : null,
                              editorName: 'Sumit (CR)',
                            );
                        if (context.mounted) {
                          Navigator.pop(modalCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Status updated • Sent to 58 classmates in CSE 3rd Year Sec A'),
                              backgroundColor: AppTheme.primaryBlue,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: const Text('Update Status in App'),
                    ),
                    const SizedBox(height: 10),

                    // WhatsApp Single-Tap Button
                    OutlinedButton.icon(
                      icon: const Icon(Icons.share, color: Color(0xFF25D366)),
                      label: const Text('Save & Post to WhatsApp'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF25D366),
                        side: const BorderSide(color: Color(0xFF25D366)),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final note = noteController.text.trim();
                        await ref.read(todayStatusesProvider.notifier).setStatus(
                              entryId: item.entry.id,
                              status: selectedStatus,
                              note: note.isNotEmpty ? note : null,
                              updatedRoom: selectedStatus == ClassStatusType.roomMoved ? roomController.text.trim() : null,
                              editorName: 'Sumit (CR)',
                            );

                        // Format WhatsApp message
                        final subject = item.entry.subject;
                        final time = item.entry.startTime;
                        String statusDesc = selectedStatus.displayName;
                        if (selectedStatus == ClassStatusType.cancelled) {
                          statusDesc = 'cancelled today';
                        } else if (selectedStatus == ClassStatusType.roomMoved) {
                          statusDesc = 'moved to ${roomController.text.trim()}';
                        }
                        final notePart = note.isNotEmpty ? ' ($note)' : '';
                        final message = '$subject $time $statusDesc$notePart. Live timetable: https://rostra.ai/p/$pageId';

                        final url = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(message)}');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        } else {
                          // Fallback to web link
                          final webUrl = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
                          await launchUrl(webUrl, mode: LaunchMode.externalApplication);
                        }

                        if (context.mounted) Navigator.pop(modalCtx);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDayOverrideDialog(BuildContext context, WidgetRef ref, DayOverride? current) {
    bool isNoClass = current?.isNoClasses ?? false;
    String followsDay = current?.followsWeekday ?? 'FRIDAY';
    final noteCtrl = TextEditingController(text: current?.note ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dCtx, setDialogState) {
            return AlertDialog(
              title: const Text('Set Day Override'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('No Classes Today (Holiday)'),
                    value: isNoClass,
                    onChanged: (val) {
                      setDialogState(() => isNoClass = val);
                    },
                  ),
                  if (!isNoClass) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: followsDay,
                      decoration: const InputDecoration(labelText: 'Follows Schedule Of'),
                      items: const [
                        DropdownMenuItem(value: 'MONDAY', child: Text('Monday')),
                        DropdownMenuItem(value: 'TUESDAY', child: Text('Tuesday')),
                        DropdownMenuItem(value: 'WEDNESDAY', child: Text('Wednesday')),
                        DropdownMenuItem(value: 'THURSDAY', child: Text('Thursday')),
                        DropdownMenuItem(value: 'FRIDAY', child: Text('Friday')),
                        DropdownMenuItem(value: 'SATURDAY', child: Text('Saturday')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => followsDay = val);
                      },
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(labelText: 'Reason / Note'),
                  ),
                ],
              ),
              actions: [
                if (current != null)
                  TextButton(
                    onPressed: () {
                      ref.read(todayOverrideProvider.notifier).clearOverride();
                      Navigator.pop(dCtx);
                    },
                    child: const Text('Clear Override', style: TextStyle(color: Colors.red)),
                  ),
                TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    await ref.read(todayOverrideProvider.notifier).setOverride(
                          isNoClasses: isNoClass,
                          followsWeekday: isNoClass ? null : followsDay,
                          note: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : null,
                        );
                    if (context.mounted) Navigator.pop(dCtx);
                  },
                  child: const Text('Apply Override'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditPageDialog(BuildContext context, WidgetRef ref, ClassPage? page) {
    final collegeCtrl = TextEditingController(text: page?.college ?? '');
    final deptCtrl = TextEditingController(text: page?.department ?? '');
    final yearCtrl = TextEditingController(text: page?.year ?? '');
    final secCtrl = TextEditingController(text: page?.section ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Class Page Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: collegeCtrl, decoration: const InputDecoration(labelText: 'College Name')),
                const SizedBox(height: 10),
                TextField(controller: deptCtrl, decoration: const InputDecoration(labelText: 'Department')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: yearCtrl, decoration: const InputDecoration(labelText: 'Year'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: secCtrl, decoration: const InputDecoration(labelText: 'Section'))),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (page != null) {
                  final updated = ClassPage(
                    id: page.id,
                    college: collegeCtrl.text.trim(),
                    department: deptCtrl.text.trim(),
                    year: yearCtrl.text.trim(),
                    section: secCtrl.text.trim(),
                    createdBy: page.createdBy,
                    createdByName: page.createdByName,
                    editors: page.editors,
                    availableGroups: page.availableGroups,
                  );
                  await ref.read(currentPageProvider.notifier).updatePage(updated);
                }
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save Details'),
            ),
          ],
        );
      },
    );
  }
}
