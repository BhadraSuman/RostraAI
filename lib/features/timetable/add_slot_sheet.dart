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

  @override
  void initState() {
    super.initState();
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
              widget.existing == null ? 'Add Class Slot' : 'Edit Class Slot',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textStone900,
              ),
            ),
            const SizedBox(height: 16),

            // Subject Name
            Text(
              'Subject Name',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textStone700),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _subjectCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Operating Systems',
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),

            // Course Code & Room
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Course Code',
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

            // Faculty Name
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
                        courseCode: _codeCtrl.text.trim().isNotEmpty ? _codeCtrl.text.trim() : null,
                        room: _roomCtrl.text.trim().isNotEmpty ? _roomCtrl.text.trim() : 'TBA',
                        teacher: _facultyCtrl.text.trim().isNotEmpty ? _facultyCtrl.text.trim() : 'Faculty',
                        startTime: _startCtrl.text.trim(),
                        endTime: _endCtrl.text.trim(),
                        group: _selectedBatch,
                      )
                    : TimetableEntry(
                        id: 'slot_${DateTime.now().millisecondsSinceEpoch}',
                        day: widget.currentDay,
                        startTime: _startCtrl.text.trim(),
                        endTime: _endCtrl.text.trim(),
                        subject: _subjectCtrl.text.trim(),
                        room: _roomCtrl.text.trim().isNotEmpty ? _roomCtrl.text.trim() : 'TBA',
                        teacher: _facultyCtrl.text.trim().isNotEmpty ? _facultyCtrl.text.trim() : 'Faculty',
                        courseCode: _codeCtrl.text.trim().isNotEmpty ? _codeCtrl.text.trim() : null,
                        group: _selectedBatch,
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
