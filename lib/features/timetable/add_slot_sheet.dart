import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/timetable_models.dart';

class AddSlotSheet extends StatefulWidget {
  final String currentDay;
  final TimetableEntry? existing;
  final void Function(TimetableEntry entry) onSave;

  const AddSlotSheet({
    super.key,
    required this.currentDay,
    this.existing,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required String currentDay,
    TimetableEntry? existing,
    required void Function(TimetableEntry entry) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddSlotSheet(
        currentDay: currentDay,
        existing: existing,
        onSave: onSave,
      ),
    );
  }

  @override
  State<AddSlotSheet> createState() => _AddSlotSheetState();
}

class _AddSlotSheetState extends State<AddSlotSheet> {
  late TextEditingController _subjectCtrl;
  late TextEditingController _codeCtrl;
  late TextEditingController _roomCtrl;
  late TextEditingController _facultyCtrl;
  late TextEditingController _startCtrl;
  late TextEditingController _endCtrl;
  String _selectedBatch = 'All';
  bool _isBreak = false;

  @override
  void initState() {
    super.initState();
    _isBreak = widget.existing?.isBreak ?? false;
    _subjectCtrl = TextEditingController(text: widget.existing?.subject ?? '');
    _codeCtrl = TextEditingController(text: widget.existing?.courseCode ?? '');
    _roomCtrl = TextEditingController(text: widget.existing?.room ?? '');
    _facultyCtrl = TextEditingController(text: widget.existing?.teacher ?? '');
    _startCtrl = TextEditingController(text: widget.existing?.startTime ?? '09:00');
    _endCtrl = TextEditingController(text: widget.existing?.endTime ?? '10:00');
    _selectedBatch = widget.existing?.group ?? 'All';
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _codeCtrl.dispose();
    _roomCtrl.dispose();
    _facultyCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: bottomInset + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderStone,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Text(
              widget.existing == null ? 'Add Timetable Slot' : 'Edit Timetable Slot',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textStone900,
              ),
            ),
            const SizedBox(height: 14),

            // Slot Type Selector (Class / Lecture vs Break / Recess)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderStone),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isBreak = false;
                          if (_subjectCtrl.text == 'Lunch Break' || _subjectCtrl.text == 'Recess') {
                            _subjectCtrl.clear();
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: !_isBreak ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: !_isBreak
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.school_rounded,
                              size: 16,
                              color: !_isBreak ? AppTheme.burntOrange : AppTheme.textStone500,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Class / Lecture',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: !_isBreak ? FontWeight.w700 : FontWeight.w500,
                                color: !_isBreak ? AppTheme.burntOrange : AppTheme.textStone600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isBreak = true;
                          if (_subjectCtrl.text.trim().isEmpty) {
                            _subjectCtrl.text = 'Lunch Break';
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _isBreak ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: _isBreak
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_cafe_rounded,
                              size: 16,
                              color: _isBreak ? AppTheme.burntOrange : AppTheme.textStone500,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Break / Recess',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: _isBreak ? FontWeight.w700 : FontWeight.w500,
                                color: _isBreak ? AppTheme.burntOrange : AppTheme.textStone600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Subject / Break Name
            Text(
              _isBreak ? 'Break Title' : 'Subject Name',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textStone700),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _subjectCtrl,
              decoration: InputDecoration(
                hintText: _isBreak ? 'e.g. Lunch Break, Recess, Free Slot' : 'e.g. Operating Systems',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),

            // Course Code & Room (Only if not break)
            if (!_isBreak) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Course Code (Optional)',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textStone700),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _codeCtrl,
                          decoration: const InputDecoration(
                            hintText: 'e.g. CS301',
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Room Number',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textStone700),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _roomCtrl,
                          decoration: const InputDecoration(
                            hintText: 'e.g. TP-301',
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // Start & End Time
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Time',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textStone700),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _startCtrl,
                        decoration: const InputDecoration(
                          hintText: '09:00',
                          prefixIcon: Icon(Icons.access_time_rounded, size: 18),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'End Time',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textStone700),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _endCtrl,
                        decoration: const InputDecoration(
                          hintText: '10:00',
                          prefixIcon: Icon(Icons.access_time_rounded, size: 18),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Faculty Name (Only if not break)
            if (!_isBreak) ...[
              Text(
                'Faculty Name',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textStone700),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _facultyCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. Dr. Anita Verma',
                  prefixIcon: Icon(Icons.school_outlined, size: 20),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Audience / Batch Chips
            Text(
              'Audience / Batch',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textStone700),
            ),
            const SizedBox(height: 8),
            Row(
              children: ['All', 'Batch 1', 'Batch 2'].map((b) {
                final isSelected = _selectedBatch == b;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          const Icon(Icons.check_rounded, size: 14, color: AppTheme.burntOrange),
                          const SizedBox(width: 4),
                        ],
                        Text(b),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: AppTheme.peachTint,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: isSelected ? AppTheme.burntOrange : AppTheme.borderStone),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppTheme.burntOrange : AppTheme.textStone700,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedBatch = b);
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Recurrence info box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_outlined, size: 18, color: AppTheme.textStone500),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Repeats every ${widget.currentDay[0] + widget.currentDay.substring(1).toLowerCase()} for Semester Odd 2024',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textStone700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Primary Button Save
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.burntOrange,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                if (_subjectCtrl.text.trim().isEmpty) return;
                final entry = widget.existing != null
                    ? widget.existing!.copyWith(
                        subject: _subjectCtrl.text.trim(),
                        courseCode: !_isBreak && _codeCtrl.text.trim().isNotEmpty ? _codeCtrl.text.trim() : null,
                        room: _isBreak ? 'Campus' : (_roomCtrl.text.trim().isNotEmpty ? _roomCtrl.text.trim() : 'TBA'),
                        teacher: _isBreak ? '' : (_facultyCtrl.text.trim().isNotEmpty ? _facultyCtrl.text.trim() : 'Faculty'),
                        startTime: _startCtrl.text.trim(),
                        endTime: _endCtrl.text.trim(),
                        group: _selectedBatch,
                        isBreak: _isBreak,
                      )
                    : TimetableEntry(
                        id: 'slot_${DateTime.now().millisecondsSinceEpoch}',
                        day: widget.currentDay,
                        startTime: _startCtrl.text.trim(),
                        endTime: _endCtrl.text.trim(),
                        subject: _subjectCtrl.text.trim(),
                        room: _isBreak ? 'Campus' : (_roomCtrl.text.trim().isNotEmpty ? _roomCtrl.text.trim() : 'TBA'),
                        teacher: _isBreak ? '' : (_facultyCtrl.text.trim().isNotEmpty ? _facultyCtrl.text.trim() : 'Faculty'),
                        courseCode: !_isBreak && _codeCtrl.text.trim().isNotEmpty ? _codeCtrl.text.trim() : null,
                        group: _selectedBatch,
                        isBreak: _isBreak,
                      );
                widget.onSave(entry);
                Navigator.pop(context);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Save slot',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Cancel Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textStone500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
