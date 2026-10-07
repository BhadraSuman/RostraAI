import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../timetable/timetable_providers.dart';

class AgeGateScreen extends ConsumerStatefulWidget {
  final VoidCallback onConfirmed;

  const AgeGateScreen({super.key, required this.onConfirmed});

  @override
  ConsumerState<AgeGateScreen> createState() => _AgeGateScreenState();
}

class _AgeGateScreenState extends ConsumerState<AgeGateScreen> {
  bool _is18Confirmed = false;
  bool _termsAccepted = false;

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Logo / Badge
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.schedule_rounded,
                      size: 40,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  AppConstants.appName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppConstants.appTagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 40),

                // Card with 18+ and Terms confirmation
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Before you begin',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'To comply with student safety and digital data guidelines (DPDP), please confirm your eligibility.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                        const Divider(height: 28),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _is18Confirmed,
                          activeColor: AppTheme.primaryBlue,
                          title: const Text(
                            'I confirm I am 18 years or older',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          onChanged: (val) {
                            setState(() => _is18Confirmed = val ?? false);
                          },
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _termsAccepted,
                          activeColor: AppTheme.primaryBlue,
                          title: const Text(
                            'I agree to the Community Guidelines and Class Terms',
                            style: TextStyle(fontSize: 13),
                          ),
                          onChanged: (val) {
                            setState(() => _termsAccepted = val ?? false);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: (_is18Confirmed && _termsAccepted)
                      ? () async {
                          await storage.setAgeConfirmed(true);
                          widget.onConfirmed();
                        }
                      : null,
                  child: const Text('Continue to Schedule'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No account required to follow your class timetable.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
