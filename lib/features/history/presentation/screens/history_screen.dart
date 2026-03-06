import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../domain/entities/sync_history_entry.dart';

/// Sync History screen (FR-4).
///
/// Chronological list of file-level sync events.
/// Wired to Riverpod for live data from Hive.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(syncHistoryStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLight,
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear History?'),
                  content: const Text(
                    'This will remove all sync history entries.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.statusError,
                      ),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(syncHistoryRepositoryProvider).clearAll();
              }
            },
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error loading history: $e',
            style: const TextStyle(color: AppTheme.statusError),
          ),
        ),
        data: (entries) => entries.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: AppTheme.textSecondary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No sync history yet',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sync events will appear here',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                itemCount: entries.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppTheme.spacingSm),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return _HistoryItemTile(entry: entry);
                },
              ),
      ),
    );
  }
}

class _HistoryItemTile extends StatelessWidget {
  const _HistoryItemTile({required this.entry});
  final SyncHistoryEntry entry;

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = entry.status == SyncHistoryStatus.success;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Status icon
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: isSuccess ? AppTheme.statusUpToDate : AppTheme.statusError,
            size: 20,
          ),
          const SizedBox(width: 12),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.taskName,
                  style: Theme.of(context).textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.filesSynced} of ${entry.totalFiles} files synced',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // Timestamp
          Text(
            _formatTimestamp(entry.timestamp),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
