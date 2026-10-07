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

    final todayDate = IstClock.todayDateString();
    final weekday = IstClock.weekdayName();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              page?.title ?? 'Class Timetable',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '$weekday, $todayDate',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          // CR Mode Switcher chip for testability
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
                          'No classes scheduled for $weekday',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enjoy your free day!',
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
                        if (context.mounted) Navigator.pop(modalCtx);
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
}
