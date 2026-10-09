import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class RoleSelectionScreen extends StatefulWidget {
  final ValueChanged<bool> onRoleSelected;
  final VoidCallback onBack;

  const RoleSelectionScreen({
    super.key,
    required this.onRoleSelected,
    required this.onBack,
  });

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  // false = Student, true = CR
  bool _isCRSelected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasPaper,
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar with Back button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textStone700),
                    tooltip: 'Back to Age Gate',
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.peachTint,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.flameOrange.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Step 2 of 3',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.burntOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Subtitle
                      Text(
                        'Choose your role',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textStone900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'RostraAI customizes your experience and tools based on how you interact with your class timetable.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textStone500,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Card 1: Student
                      _buildRoleOptionCard(
                        isCurrent: !_isCRSelected,
                        onTap: () => setState(() => _isCRSelected = false),
                        icon: Icons.school_rounded,
                        badgeText: 'MOST STUDENTS',
                        title: 'I am a Student',
                        tagline: 'Following my section schedule',
                        features: const [
                          'Instant alerts for cancelled classes or moved rooms',
                          'Glanceable attendance margin (e.g. "Can miss 2" or "Must attend 4")',
                          'Zero sign-up friction — join via class link or code',
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Card 2: Class Representative (CR)
                      _buildRoleOptionCard(
                        isCurrent: _isCRSelected,
                        onTap: () => setState(() => _isCRSelected = true),
                        icon: Icons.bolt_rounded,
                        badgeText: 'CLASS ADMIN',
                        title: 'I am a Class Representative',
                        tagline: 'Managing & broadcasting changes for my class',
                        features: const [
                          'Single-tap class cancellations & room changes',
                          '1-tap formatted broadcasts straight to WhatsApp',
                          'Schedule overrides, timetable swaps & holidays',
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Helpful Note
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.stoneBorder),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.burntOrange),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'You can switch between Student view and CR admin mode anytime from the sidebar menu (☰).',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppTheme.textStone700,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Continue Action
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.stoneBorder)),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.burntOrange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      widget.onRoleSelected(_isCRSelected);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isCRSelected ? 'Continue as Class Rep' : 'Continue as Student',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleOptionCard({
    required bool isCurrent,
    required VoidCallback onTap,
    required IconData icon,
    required String badgeText,
    required String title,
    required String tagline,
    required List<String> features,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isCurrent ? AppTheme.peachBg : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isCurrent ? AppTheme.burntOrange : AppTheme.stoneBorder,
            width: isCurrent ? 2 : 1,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: AppTheme.burntOrange.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isCurrent ? AppTheme.burntOrange : AppTheme.peachTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isCurrent ? Colors.white : AppTheme.burntOrange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isCurrent ? AppTheme.burntOrange.withValues(alpha: 0.15) : const Color(0xFFF5F5F4),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText,
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: isCurrent ? AppTheme.burntOrange : AppTheme.textStone500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textStone900,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isCurrent ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: isCurrent ? AppTheme.burntOrange : AppTheme.textStone400,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              tagline,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isCurrent ? AppTheme.burntOrange : AppTheme.textStone700,
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppTheme.stoneBorder),
            const SizedBox(height: 10),
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 15,
                      color: isCurrent ? AppTheme.burntOrange : const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppTheme.textStone700,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
