import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../domain/entities/sync_task.dart';
import '../widgets/drive_connection_card.dart';
import '../widgets/sync_task_card.dart';

/// Dashboard screen (FR-1).
///
/// Shows Drive Connection card, sync task list, and "Add New Sync Task" button.
/// Wired to Riverpod for live auth user and sync task data.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    final tasksAsync = ref.watch(syncTasksStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.surfaceLight,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: const Icon(
                    Icons.sync_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('FolderSync'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.go(AppRoutes.profile),
              ),
            ],
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Drive Connection card — from auth user
                if (user != null)
                  DriveConnectionCard(
                    userName: user.displayName,
                    userEmail: user.email,
                    usedStorageGb: 0,
                    totalStorageGb: 15.0,
                  )
                else
                  const DriveConnectionCard(
                    userName: 'Not Connected',
                    userEmail: '—',
                    usedStorageGb: 0,
                    totalStorageGb: 15.0,
                  ),
                const SizedBox(height: AppTheme.spacingLg),

                // Sync Tasks header
                tasksAsync.when(
                  data: (tasks) => _TasksSection(tasks: tasks),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Error loading tasks: $e',
                        style: const TextStyle(color: AppTheme.statusError),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _TasksSection extends StatelessWidget {
  const _TasksSection({required this.tasks});
  final List<SyncTask> tasks;

  SyncStatus _mapStatus(SyncTaskStatus status) => switch (status) {
    SyncTaskStatus.syncing => SyncStatus.syncing,
    SyncTaskStatus.upToDate => SyncStatus.upToDate,
    SyncTaskStatus.error => SyncStatus.error,
    SyncTaskStatus.idle => SyncStatus.upToDate,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Sync Tasks', style: Theme.of(context).textTheme.titleLarge),
            Text(
              '${tasks.length} Active',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMd),

        // Add new task button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.addTask),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add New Sync Task'),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),

        if (tasks.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(
                    Icons.folder_off_outlined,
                    size: 64,
                    color: AppTheme.textSecondary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No sync tasks yet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap "Add New Sync Task" to get started',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          )
        else
          ...tasks.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
              child: SyncTaskCard(
                taskName: task.name,
                remotePath: task.remotePath,
                localPath: task.localPath,
                status: _mapStatus(task.status),
                progress: task.progress,
                filesRemaining: task.filesRemaining,
                isTwoWay: task.isTwoWaySync,
                errorMessage: task.errorMessage,
              ),
            ),
          ),
      ],
    );
  }
}
