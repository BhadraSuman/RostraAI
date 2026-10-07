import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../timetable/timetable_providers.dart';
import 'attendance_calculator.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(attendanceProvider);
    final notifier = ref.read(attendanceProvider.notifier);
    final todaySchedule = ref.watch(todayScheduleProvider);

    // Identify subjects cancelled today by the CR
    final cancelledSubjectsToday = todaySchedule
        .where((item) => item.isCancelled)
        .map((item) => item.entry.subject.toLowerCase())
        .toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Margin', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showTargetDialog(context, state.targetPercent, notifier),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner explaining the Attendance Margin
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Target: ${state.targetPercent}% Attendance',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                    ),
                    InkWell(
                      onTap: () => _showTargetDialog(context, state.targetPercent, notifier),
                      child: const Text('Edit Target', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Shows exactly how many classes you can afford to miss, or must attend in a row to remain eligible.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.lock_outline, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      'Private to your phone • 0 server logs',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Subject List
          ...state.records.values.map((record) {
            final margin = calculateAttendanceMargin(record.attended, record.held, state.targetPercent);
            final isSafe = margin >= 0;
            final isCancelledToday = cancelledSubjectsToday.contains(record.subject.toLowerCase());

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            record.subject,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSafe ? AppTheme.statusNormal.withValues(alpha: 0.12) : AppTheme.statusCancelled.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isSafe ? 'Can miss $margin' : 'Attend ${margin.abs()} in a row',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSafe ? AppTheme.statusNormal : AppTheme.statusCancelled,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (isCancelledToday) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline, size: 13, color: AppTheme.statusCancelled),
                            const SizedBox(width: 4),
                            Text(
                              "Cancelled today by CR (excluded from held classes)",
                              style: TextStyle(fontSize: 11, color: Colors.red.shade900, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: record.held > 0 ? (record.attended / record.held).clamp(0.0, 1.0) : 1.0,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(isSafe ? AppTheme.statusNormal : AppTheme.statusCancelled),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Attended numbers and quick check-in actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${record.attended} / ${record.held} attended (${record.percentage.toStringAsFixed(1)}%)',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                        ),
                        Row(
                          children: [
                            IconButton.filledTonal(
                              icon: const Icon(Icons.check, size: 18),
                              tooltip: 'Mark Attended',
                              onPressed: () => notifier.markAttended(record.subject),
                            ),
                            const SizedBox(width: 6),
                            IconButton.filledTonal(
                              icon: const Icon(Icons.close, size: 18),
                              tooltip: 'Mark Missed',
                              onPressed: () => notifier.markMissed(record.subject),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showTargetDialog(BuildContext context, int current, AttendanceNotifier notifier) {
    int selected = current;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dCtx, setDialogState) {
            return AlertDialog(
              title: const Text('Required Percentage'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$selected%', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                  Slider(
                    value: selected.toDouble(),
                    min: 50,
                    max: 95,
                    divisions: 9,
                    label: '$selected%',
                    onChanged: (val) {
                      setDialogState(() => selected = val.toInt());
                    },
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
}
