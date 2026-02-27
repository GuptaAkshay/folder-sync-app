import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// Sync status enum matching Stitch design states.
enum SyncStatus { syncing, upToDate, error }

/// Sync Task card widget (FR-2).
///
/// Displays task name, remote/local paths, status badge,
/// progress bar, and optional 2-Way badge.
class SyncTaskCard extends StatelessWidget {
  const SyncTaskCard({
    super.key,
    required this.taskName,
    required this.remotePath,
    required this.localPath,
    required this.status,
    this.progress,
    this.filesRemaining,
    this.isTwoWay = false,
    this.errorMessage,
    this.onEdit,
  });

  final String taskName;
  final String remotePath;
  final String localPath;
  final SyncStatus status;
  final double? progress;
  final int? filesRemaining;
  final bool isTwoWay;
  final String? errorMessage;
  final VoidCallback? onEdit;

  Color get _statusColor => switch (status) {
    SyncStatus.syncing => AppTheme.statusSyncing,
    SyncStatus.upToDate => AppTheme.statusUpToDate,
    SyncStatus.error => AppTheme.statusError,
  };

  Color get _statusBgColor => switch (status) {
    SyncStatus.syncing => AppTheme.statusSyncingBg,
    SyncStatus.upToDate => AppTheme.statusUpToDateBg,
    SyncStatus.error => AppTheme.statusErrorBg,
  };

  String get _statusLabel => switch (status) {
    SyncStatus.syncing => 'SYNCING',
    SyncStatus.upToDate => 'UP TO DATE',
    SyncStatus.error => 'ERROR',
  };

  IconData get _statusIcon => switch (status) {
    SyncStatus.syncing => Icons.cloud_download,
    SyncStatus.upToDate => Icons.check_circle,
    SyncStatus.error => Icons.error,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: status == SyncStatus.error
              ? AppTheme.statusError.withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _statusBgColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(_statusIcon, color: _statusColor, size: 20),
              ),
              const SizedBox(width: 12),

              // Task info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      taskName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    _PathRow(icon: Icons.cloud, text: remotePath),
                    _PathRow(icon: Icons.folder, text: localPath),
                  ],
                ),
              ),

              // Badges & edit
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isTwoWay)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sync_alt,
                            size: 12,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '2-WAY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusBgColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text(
                      _statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _statusColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Edit button
                  GestureDetector(
                    onTap: onEdit,
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Progress bar (syncing only)
          if (status == SyncStatus.syncing && progress != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filesRemaining ?? 0} files remaining',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${(progress! * 100).round()}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.statusSyncing,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.statusSyncing,
                ),
                minHeight: 8,
              ),
            ),
          ],

          // Up to date progress bar
          if (status == SyncStatus.upToDate) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              child: const LinearProgressIndicator(
                value: 1.0,
                backgroundColor: Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.statusUpToDate,
                ),
                minHeight: 8,
              ),
            ),
          ],

          // Error message
          if (status == SyncStatus.error && errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.statusError,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PathRow extends StatelessWidget {
  const _PathRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
