import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';

class AppUpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;

  const AppUpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
  });
}

class UpdateCheckerService {
  static Future<AppUpdateInfo?> checkForUpdate() async {
    if (AppConstants.githubRepo.isEmpty) return null;
    try {
      final url = Uri.parse('https://api.github.com/repos/${AppConstants.githubRepo}/releases/latest');
      final response = await http.get(
        url,
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final rawTag = data['tag_name'] as String? ?? '';
      final latestVer = rawTag.replaceAll(RegExp(r'^[vV]'), '').trim();
      final currentVer = AppConstants.appVersion.trim();
      final body = data['body'] as String? ?? 'Bug fixes and performance improvements.';

      // Find the APK download URL from assets
      String downloadUrl = data['html_url'] as String? ?? '';
      final assets = data['assets'] as List<dynamic>? ?? [];
      for (final asset in assets) {
        final name = (asset['name'] as String? ?? '').toLowerCase();
        if (name.endsWith('.apk')) {
          downloadUrl = asset['browser_download_url'] as String? ?? downloadUrl;
          break;
        }
      }

      final hasUpdate = isVersionGreater(latestVer, currentVer);

      return AppUpdateInfo(
        hasUpdate: hasUpdate,
        currentVersion: currentVer,
        latestVersion: latestVer,
        downloadUrl: downloadUrl,
        releaseNotes: body,
      );
    } catch (_) {
      // Fail silently if offline or network error
      return null;
    }
  }

  static bool isVersionGreater(String remote, String local) {
    final remoteParts = remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final localParts = local.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    while (remoteParts.length < 3) {
      remoteParts.add(0);
    }
    while (localParts.length < 3) {
      localParts.add(0);
    }

    for (int i = 0; i < 3; i++) {
      if (remoteParts[i] > localParts[i]) return true;
      if (remoteParts[i] < localParts[i]) return false;
    }
    return false;
  }

  static void showUpdateDialog(BuildContext context, AppUpdateInfo info) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.peachTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.system_update_rounded, color: AppTheme.burntOrange, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Update Available',
                    style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.peachBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.peachTint),
                        ),
                        child: Text(
                          'v${info.latestVersion}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.burntOrange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(Current: v${info.currentVersion})',
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textStone400),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "What's New:",
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textStone700),
            ),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 120),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SingleChildScrollView(
                child: Text(
                  info.releaseNotes,
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textStone700, height: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tapping "Update Now" will download the latest APK and update the app automatically on your phone.',
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textStone500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Later',
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textStone500),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.burntOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final rawUrl = info.downloadUrl.isNotEmpty
                  ? info.downloadUrl
                  : 'https://github.com/${AppConstants.githubRepo}/releases/latest';
              final url = Uri.parse(rawUrl);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening browser to download RostraAI update...'),
                    duration: Duration(seconds: 3),
                  ),
                );
              }

              try {
                final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
                if (!launched) {
                  await launchUrl(url, mode: LaunchMode.platformDefault);
                }
              } catch (_) {
                try {
                  await launchUrl(url, mode: LaunchMode.platformDefault);
                } catch (_) {
                  final fallbackUrl = Uri.parse('https://github.com/${AppConstants.githubRepo}/releases/latest');
                  await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
                }
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.download_rounded, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Update Now',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
