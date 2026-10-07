import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/timetable_models.dart';
import 'timetable_providers.dart';

class TimetableGridScreen extends ConsumerStatefulWidget {
  const TimetableGridScreen({super.key});

  @override
  ConsumerState<TimetableGridScreen> createState() => _TimetableGridScreenState();
}

class _TimetableGridScreenState extends ConsumerState<TimetableGridScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _days = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _days.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(timetableEntriesProvider);
    final isEditor = ref.watch(isEditorModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Timetable', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryBlue,
          tabs: _days.map((d) => Tab(text: d.substring(0, 3))).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _days.map((day) {
          final dayEntries = entries.where((e) => e.day == day).toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime));

          if (dayEntries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('No classes for $day', style: TextStyle(color: Colors.grey.shade600)),
                  if (isEditor) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showAddOrEditDialog(context, day: day),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Class Slot'),
                    ),
                  ],
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dayEntries.length,
            itemBuilder: (context, index) {
              final entry = dayEntries[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${entry.startTime}\n${entry.endTime}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                    ),
                  ),
                  title: Text(entry.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${entry.room} • ${entry.teacher} • Group: ${entry.group}'),
                  trailing: isEditor
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => _showAddOrEditDialog(context, day: day, existing: entry),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                              onPressed: () {
                                ref.read(timetableEntriesProvider.notifier).removeEntry(entry.id);
                              },
                            ),
                          ],
                        )
                      : null,
                ),
              );
            },
          );
        }).toList(),
      ),
      floatingActionButton: isEditor
          ? FloatingActionButton.extended(
              onPressed: () {
                final currentDay = _days[_tabController.index];
                _showAddOrEditDialog(context, day: currentDay);
              },
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Class'),
            )
          : null,
    );
  }

  void _showAddOrEditDialog(BuildContext context, {required String day, TimetableEntry? existing}) {
    final subjectCtrl = TextEditingController(text: existing?.subject ?? '');
    final roomCtrl = TextEditingController(text: existing?.room ?? '');
    final teacherCtrl = TextEditingController(text: existing?.teacher ?? '');
    final startCtrl = TextEditingController(text: existing?.startTime ?? '10:00');
    final endCtrl = TextEditingController(text: existing?.endTime ?? '11:00');
    String group = existing?.group ?? 'All';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dCtx, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add Class to $day' : 'Edit Class'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: subjectCtrl, decoration: const InputDecoration(labelText: 'Subject Name')),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Start Time (HH:mm)')),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'End Time (HH:mm)')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: roomCtrl, decoration: const InputDecoration(labelText: 'Room Number')),
                    const SizedBox(height: 10),
                    TextField(controller: teacherCtrl, decoration: const InputDecoration(labelText: 'Teacher Name')),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: group,
                      decoration: const InputDecoration(labelText: 'Group / Batch'),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All Classmates')),
                        DropdownMenuItem(value: 'B1', child: Text('Batch 1 (B1)')),
                        DropdownMenuItem(value: 'B2', child: Text('Batch 2 (B2)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => group = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (subjectCtrl.text.trim().isEmpty) return;
                    if (existing == null) {
                      await ref.read(timetableEntriesProvider.notifier).addEntry(
                            day: day,
                            startTime: startCtrl.text.trim(),
                            endTime: endCtrl.text.trim(),
                            subject: subjectCtrl.text.trim(),
                            room: roomCtrl.text.trim(),
                            teacher: teacherCtrl.text.trim(),
                            group: group,
                          );
                    } else {
                      await ref.read(timetableEntriesProvider.notifier).updateEntry(
                            existing.copyWith(
                              startTime: startCtrl.text.trim(),
                              endTime: endCtrl.text.trim(),
                              subject: subjectCtrl.text.trim(),
                              room: roomCtrl.text.trim(),
                              teacher: teacherCtrl.text.trim(),
                              group: group,
                            ),
                          );
                    }
                    if (context.mounted) Navigator.pop(dCtx);
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
