import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// Drive Connection status card (FR-1).
///
/// Shows the connected Google account info and Drive storage usage.
class DriveConnectionCard extends StatelessWidget {
  const DriveConnectionCard({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.usedStorageGb,
    required this.totalStorageGb,
    this.isLoading = false,
  });

  final String userName;
  final String userEmail;
  final double usedStorageGb;
  final double totalStorageGb;
  final bool isLoading;

  double get _usagePercent => (usedStorageGb / totalStorageGb).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final percentage = (_usagePercent * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // User info row
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.cloud,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      userEmail,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.info_outline,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Storage usage
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: LinearProgressIndicator(
                backgroundColor: Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                minHeight: 10,
              ),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Used: ${usedStorageGb.toStringAsFixed(1)} GB / '
                  'Total: ${totalStorageGb.toStringAsFixed(0)} GB',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              child: LinearProgressIndicator(
                value: _usagePercent,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primary,
                ),
                minHeight: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
