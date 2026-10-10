import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/firestore_sync_service.dart';
import '../auth/auth_provider.dart';
import '../timetable/timetable_providers.dart';

class UserProfileSetupScreen extends ConsumerStatefulWidget {
  final VoidCallback onProfileComplete;

  const UserProfileSetupScreen({super.key, required this.onProfileComplete});

  @override
  ConsumerState<UserProfileSetupScreen> createState() => _UserProfileSetupScreenState();
}

class _UserProfileSetupScreenState extends ConsumerState<UserProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _institutionController;
  String? _selectedGender;
  bool _isLoading = false;
  List<String> _institutionSuggestions = [];
  bool _showSuggestions = false;

  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];

  @override
  void initState() {
    super.initState();
    final storage = ref.read(storageProvider);
    _nameController = TextEditingController(text: storage.getUserName() ?? '');
    _institutionController = TextEditingController(text: storage.getUserInstitution() ?? '');
    _selectedGender = storage.getUserGender();

    _loadInstitutionSuggestions('');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _institutionController.dispose();
    super.dispose();
  }

  Future<void> _loadInstitutionSuggestions(String query) async {
    final list = await FirestoreSyncService.searchInstitutions(query);
    if (mounted) {
      setState(() => _institutionSuggestions = list);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final institution = _institutionController.text.trim();

    setState(() => _isLoading = true);

    try {
      final storage = ref.read(storageProvider);
      await storage.updateUserProfile(
        name: name,
        gender: _selectedGender,
        institution: institution,
      );

      // Save institution to cloud directory if new
      await FirestoreSyncService.addInstitution(institution);

      // Update in-memory auth provider
      final current = ref.read(authProvider);
      if (current != null) {
        ref.read(authProvider.notifier).setUser(
          current.copyWith(
            name: name,
            gender: _selectedGender,
            institution: institution,
          ),
        );
      }

      if (mounted) {
        widget.onProfileComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasPaper,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Step Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.peachTint,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Step 1 of 2 • Profile',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.burntOrange,
                            ),
                          ),
                        ),
                        Text(
                          'Campus Details',
                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textStone400),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Heading
                    Text(
                      'Tell us about yourself',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textStone900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select your institution so we can find your class timetable cohort.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textStone600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Full Name (Required)
                    Text(
                      'Full Name *',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textStone700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Suman Bhadra',
                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.stoneBorder),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Gender (Optional)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Gender',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textStone700,
                          ),
                        ),
                        Text(
                          'Optional',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.textStone400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      decoration: InputDecoration(
                        hintText: 'Select gender (optional)',
                        prefixIcon: const Icon(Icons.wc_outlined, size: 20),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.stoneBorder),
                        ),
                      ),
                      items: _genderOptions
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedGender = val),
                    ),
                    const SizedBox(height: 20),

                    // Institution / College (Search & Add)
                    Text(
                      'College / Institution *',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textStone700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _institutionController,
                      decoration: InputDecoration(
                        hintText: 'Search your college or campus...',
                        prefixIcon: const Icon(Icons.school_outlined, size: 20),
                        suffixIcon: _institutionController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _institutionController.clear();
                                  _loadInstitutionSuggestions('');
                                  setState(() => _showSuggestions = true);
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.stoneBorder),
                        ),
                      ),
                      onChanged: (val) {
                        _loadInstitutionSuggestions(val);
                        setState(() => _showSuggestions = true);
                      },
                      onTap: () => setState(() => _showSuggestions = true),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please select or add your institution';
                        }
                        return null;
                      },
                    ),

                    // Suggestions List
                    if (_showSuggestions) ...[
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.stoneBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListView(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          children: [
                            ..._institutionSuggestions.map(
                              (inst) => ListTile(
                                dense: true,
                                leading: const Icon(Icons.domain_rounded, size: 18, color: AppTheme.burntOrange),
                                title: Text(inst, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textStone900)),
                                onTap: () {
                                  _institutionController.text = inst;
                                  setState(() => _showSuggestions = false);
                                },
                              ),
                            ),
                            // Option to add typed university if not in list
                            if (_institutionController.text.trim().isNotEmpty &&
                                !_institutionSuggestions.any(
                                  (s) => s.toLowerCase() == _institutionController.text.trim().toLowerCase(),
                                ))
                              ListTile(
                                dense: true,
                                tileColor: AppTheme.peachBg,
                                leading: const Icon(Icons.add_circle_outline_rounded, size: 18, color: AppTheme.burntOrange),
                                title: Text(
                                  '+ Add "${_institutionController.text.trim()}"',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.burntOrange,
                                  ),
                                ),
                                subtitle: Text(
                                  'Register new campus in directory',
                                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textStone500),
                                ),
                                onTap: () {
                                  setState(() => _showSuggestions = false);
                                },
                              ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.burntOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : Text(
                              'Save & Find Classes',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
