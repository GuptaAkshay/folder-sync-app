import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../shared/providers/app_providers.dart';

/// Profile / Settings screen (FR-8, P0).
///
/// Shows connected Google account info and disconnect action.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLight,
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          children: [
            // Account card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(36),
                    ),
                    child: user?.photoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(36),
                            child: Image.network(
                              user!.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.person,
                                color: AppTheme.primary,
                                size: 36,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            color: AppTheme.primary,
                            size: 36,
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.displayName ?? 'Not Connected',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: user != null
                          ? AppTheme.statusUpToDateBg
                          : AppTheme.statusErrorBg,
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Text(
                      user != null ? 'Connected' : 'Disconnected',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: user != null
                            ? AppTheme.statusUpToDate
                            : AppTheme.statusError,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Disconnect button
            if (user != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showDisconnectDialog(context, ref),
                  icon: const Icon(Icons.link_off, color: AppTheme.statusError),
                  label: const Text('Disconnect Google Account'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.statusError,
                    side: const BorderSide(color: AppTheme.statusError),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDisconnectDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect Google Account?'),
        content: const Text(
          'This will remove your Google Drive connection. '
          'You can reconnect at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authStateProvider.notifier).signOut();
              // Auth guard will redirect to welcome
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.statusError),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }
}
