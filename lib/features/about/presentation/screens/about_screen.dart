import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/app_constants.dart';

/// About screen (FR-9, P2).
///
/// Shows app version, description, and links.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLight,
        title: const Text('About'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          children: [
            const SizedBox(height: 32),

            // App icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              ),
              child: const Icon(Icons.sync_alt, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 16),

            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Version ${AppConstants.appVersion}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Text(
              'Keep your folders perfectly in sync between '
              'Google Drive and your Android device.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Info items
            _AboutItem(
              icon: Icons.shield_outlined,
              label: 'Privacy Policy',
              onTap: () {
                /* TODO */
              },
            ),
            _AboutItem(
              icon: Icons.description_outlined,
              label: 'Terms of Service',
              onTap: () {
                /* TODO */
              },
            ),
            _AboutItem(
              icon: Icons.code,
              label: 'Licenses',
              onTap: () => showLicensePage(
                context: context,
                applicationName: AppConstants.appName,
                applicationVersion: AppConstants.appVersion,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutItem extends StatelessWidget {
  const _AboutItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.textSecondary),
        title: Text(label),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppTheme.textSecondary,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        tileColor: AppTheme.surfaceLight,
      ),
    );
  }
}
