import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../models/timetable_models.dart';
import '../../services/firestore_sync_service.dart';
import '../timetable/timetable_providers.dart';

class ClassDiscoveryScreen extends ConsumerStatefulWidget {
  final void Function(ClassPage page, bool isCR)? onClassSelected;
  final VoidCallback? onBack;

  const ClassDiscoveryScreen({
    super.key,
    this.onClassSelected,
    this.onBack,
  });

  @override
  ConsumerState<ClassDiscoveryScreen> createState() => _ClassDiscoveryScreenState();
}

class _ClassDiscoveryScreenState extends ConsumerState<ClassDiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ClassPage> _classes = [];
  bool _isLoading = true;
  String _institution = '';

  @override
  void initState() {
    super.initState();
    final storage = ref.read(storageProvider);
    _institution = storage.getUserInstitution() ?? 'SRM Institute of Science and Technology';
    _loadClasses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    final results = await FirestoreSyncService.fetchClassesForInstitution(_institution);

    // If none found in cloud for this college yet, provide default template cohort
    if (results.isEmpty) {
      results.add(
        ClassPage(
          id: 'demo-class-101',
          college: _institution,
          department: 'Computer Science & Engineering',
          year: '3rd Year',
          section: 'Section A',
          classCode: _generateDefaultCode(_institution, 'CSE', '3A'),
          createdBy: 'cr-sample-1',
          createdByName: 'Sumit (CR)',
          editors: const ['cr-sample-1'],
        ),
      );
    }

    if (mounted) {
      setState(() {
        _classes = results;
        _isLoading = false;
      });
    }
  }

  String _generateDefaultCode(String college, String dept, String sec) {
    final prefix = college.split(' ').map((w) => w[0]).take(3).join().toUpperCase();
    return '$prefix-$dept-$sec'.replaceAll(RegExp(r'[^A-Z0-9\-]'), '');
  }

  Future<void> _handleSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      _loadClasses();
      return;
    }

    // Try direct code lookup first
    final byCode = await FirestoreSyncService.searchClassByCode(clean);
    if (byCode != null && mounted) {
      setState(() => _classes = [byCode]);
      return;
    }

    // Otherwise filter in-memory list
    final filtered = _classes.where((c) {
      final text = '${c.department} ${c.year} ${c.section} ${c.classCode}'.toLowerCase();
      return text.contains(clean.toLowerCase());
    }).toList();

    if (mounted) setState(() => _classes = filtered);
  }

  void _showCreateClassDialog() {
    final deptController = TextEditingController(text: 'Computer Science & Engineering');
    final yearController = TextEditingController(text: '3rd Year');
    final secController = TextEditingController(text: 'Section A');
    final codeController = TextEditingController(
      text: _generateDefaultCode(_institution, 'CSE', '3A'),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Create New Class Page',
                    style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'You will become the Class Representative (CR) for this timetable.',
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textStone500),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: deptController,
                decoration: const InputDecoration(
                  labelText: 'Department / Branch',
                  prefixIcon: Icon(Icons.apartment_rounded, size: 20),
                ),
                onChanged: (_) {
                  final deptCode = deptController.text.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(3).join();
                  codeController.text = _generateDefaultCode(_institution, deptCode, secController.text.replaceAll(' ', ''));
                  setModalState(() {});
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: yearController,
                      decoration: const InputDecoration(labelText: 'Year / Sem'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: secController,
                      decoration: const InputDecoration(labelText: 'Section / Batch'),
                      onChanged: (_) {
                        final deptCode = deptController.text.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(3).join();
                        codeController.text = _generateDefaultCode(_institution, deptCode, secController.text.replaceAll(' ', ''));
                        setModalState(() {});
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Class Code (Share with classmates)',
                  helperText: 'Auto-generated clean code, editable',
                  prefixIcon: const Icon(Icons.tag_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    onPressed: () {
                      final deptCode = deptController.text.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(3).join();
                      codeController.text = _generateDefaultCode(_institution, deptCode, secController.text.replaceAll(' ', ''));
                      setModalState(() {});
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final storage = ref.read(storageProvider);
                  final userUid = storage.getUserId() ?? 'cr_${DateTime.now().millisecondsSinceEpoch}';
                  final userName = storage.getUserName() ?? 'CR';
                  final newId = 'class_${codeController.text.trim().toLowerCase().replaceAll('-', '_')}';

                  final newPage = ClassPage(
                    id: newId,
                    college: _institution,
                    department: deptController.text.trim(),
                    year: yearController.text.trim(),
                    section: secController.text.trim(),
                    classCode: codeController.text.trim().toUpperCase(),
                    createdBy: userUid,
                    createdByName: '$userName (CR)',
                    editors: [userUid],
                  );

                  // Create in Firestore
                  await FirestoreSyncService.createClassPage(newPage);

                  // Seed default sample schedule so it is ready immediately
                  await ref.read(timetableEntriesProvider.notifier).seedSampleSchedule();

                  if (ctx.mounted) Navigator.pop(ctx);

                  // Show WhatsApp invite prompt
                  if (mounted) {
                    _showWhatsAppShareModal(newPage);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.burntOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Create Class & Get Code',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWhatsAppShareModal(ClassPage page) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
              child: const Icon(Icons.share_rounded, color: Color(0xFF16A34A), size: 20),
            ),
            const SizedBox(width: 10),
            Text('Class Created!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your class code is:',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textStone500),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.peachBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.peachTint),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    page.displayCode,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.burntOrange,
                      letterSpacing: 1.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18, color: AppTheme.burntOrange),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: page.displayCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Class code copied!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Share this code with your classmates on WhatsApp so they can join your live timetable broadcast.',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textStone600, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final storage = ref.read(storageProvider);
              await storage.addFollowedPage(page.id);
              await ref.read(currentPageProvider.notifier).updatePage(page);
              ref.read(isEditorModeProvider.notifier).setMode(true);

              if (widget.onClassSelected != null) {
                widget.onClassSelected!(page, true);
              } else if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Later'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.share_rounded, size: 16),
            label: const Text('Share on WhatsApp'),
            onPressed: () async {
              Navigator.pop(ctx);
              _shareOnWhatsApp(page);
              final storage = ref.read(storageProvider);
              await storage.addFollowedPage(page.id);
              await ref.read(currentPageProvider.notifier).updatePage(page);
              ref.read(isEditorModeProvider.notifier).setMode(true);

              if (widget.onClassSelected != null) {
                widget.onClassSelected!(page, true);
              } else if (mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _shareOnWhatsApp(ClassPage page) async {
    final text = '📢 Hey everyone! Join our official live class timetable for ${page.department} (${page.section}) on RostraAI.\n\n'
        '🔑 Class Code: *${page.displayCode}*\n\n'
        '📲 Download app: https://github.com/BhadraSuman/RostraAI/releases/latest\n\n'
        'Track cancelled classes, moved rooms, and attendance live!';
    final url = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      final webUrl = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasPaper,
      appBar: AppBar(
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: widget.onBack,
              )
            : null,
        title: Text(
          'Find Your Cohort',
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.burntOrange),
            tooltip: 'Create Class',
            onPressed: _showCreateClassDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Campus Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: Row(
                children: [
                  const Icon(Icons.domain_rounded, size: 16, color: AppTheme.burntOrange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _institution,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textStone900),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.stoneBorder),

            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by class name, branch, or code...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _loadClasses();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.stoneBorder),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onSubmitted: _handleSearch,
              ),
            ),

            // Classes List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.burntOrange))
                  : _classes.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          itemCount: _classes.length,
                          itemBuilder: (ctx, i) {
                            final c = _classes[i];
                            return _buildClassCard(c);
                          },
                        ),
            ),

            // Bottom Floating Action to Create
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.stoneBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Don\'t see your section?', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text('Be the Class Representative & setup timetable', style: GoogleFonts.inter(fontSize: 10.5, color: AppTheme.textStone500)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _showCreateClassDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.burntOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('+ Create Class'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassCard(ClassPage page) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.stoneBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  page.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textStone900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.peachTint,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  page.displayCode,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.burntOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.school_outlined, size: 14, color: AppTheme.textStone500),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  page.college,
                  style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textStone500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Managed by ${page.createdByName.isNotEmpty ? page.createdByName : "CR"}',
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textStone400),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Groups: ${page.availableGroups.join(", ")}',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.textStone500),
              ),
              ElevatedButton(
                onPressed: () async {
                  final storage = ref.read(storageProvider);
                  final currentUid = storage.getUserId();
                  final isCR = page.createdBy == currentUid || page.editors.contains(currentUid);

                  await storage.addFollowedPage(page.id);
                  await ref.read(currentPageProvider.notifier).updatePage(page);
                  ref.read(isEditorModeProvider.notifier).setMode(isCR);

                  if (widget.onClassSelected != null) {
                    widget.onClassSelected!(page, isCR);
                  } else if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Switched to ${page.department} (${page.section})!'),
                        backgroundColor: AppTheme.burntOrange,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.burntOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Join Class'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textStone400),
            const SizedBox(height: 12),
            Text(
              'No class found for "$_institution"',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Be the first to create your section timetable and share the code with classmates.',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textStone500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _showCreateClassDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.burntOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Create This Class'),
            ),
          ],
        ),
      ),
    );
  }
}
