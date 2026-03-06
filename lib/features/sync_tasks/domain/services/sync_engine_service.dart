import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../core/services/local_file_service.dart';
import '../../data/services/drive_service.dart';
import '../repositories/sync_task_repository.dart';
import '../../../history/domain/repositories/sync_history_repository.dart';
import '../repositories/sync_state_repository.dart';
import '../entities/sync_task.dart';
import '../entities/sync_state_snapshot.dart';
import '../entities/drive_file_item.dart';
import '../../../history/domain/entities/sync_history_entry.dart';
import '../../../../core/utils/app_logger.dart';

final syncEngineServiceProvider = Provider<SyncEngineService>((ref) {
  return SyncEngineService(
    localFileService: ref.watch(localFileServiceProvider),
    driveService: ref.watch(driveServiceProvider),
    taskRepository: ref.watch(syncTaskRepositoryProvider),
    historyRepository: ref.watch(syncHistoryRepositoryProvider),
    stateRepository: ref.watch(syncStateRepositoryProvider),
    ref: ref,
  );
});

// We need to provide the local file service instance globally
final localFileServiceProvider = Provider<LocalFileService>((ref) {
  return LocalFileService();
});

class SyncEngineService {
  final LocalFileService _localFileService;
  final DriveService _driveService;
  final SyncTaskRepository _taskRepository;
  final SyncHistoryRepository _historyRepository;
  final SyncStateRepository _stateRepository;
  final Ref _ref;

  SyncEngineService({
    required LocalFileService localFileService,
    required DriveService driveService,
    required SyncTaskRepository taskRepository,
    required SyncHistoryRepository historyRepository,
    required SyncStateRepository stateRepository,
    required Ref ref,
  }) : _localFileService = localFileService,
       _driveService = driveService,
       _taskRepository = taskRepository,
       _historyRepository = historyRepository,
       _stateRepository = stateRepository,
       _ref = ref;

  /// Executes a single sync task. Run this when the user requests a sync.
  Future<void> runTask(SyncTask task) async {
    AppLogger.i(
      '[SYNC_ENGINE] Starting sync for task: ${task.name} (${task.id})',
    );

    // 1. Update status to syncing
    final syncingTask = task.copyWith(
      status: SyncTaskStatus.syncing,
      errorMessage: null,
      progress: 0.0,
      filesRemaining: null,
    );
    await _taskRepository.updateTask(syncingTask);

    try {
      // Get the authenticated state to run drive operations
      final authUser = _ref.read(authStateProvider).value;
      if (authUser == null || authUser.accessToken == null) {
        throw Exception(
          'User is not authenticated or access token is missing.',
        );
      }
      final accessToken = authUser.accessToken!;

      final folderId =
          task.remotePath; // remotePath stores the raw Drive folder ID
      AppLogger.d(
        '[SYNC_ENGINE] Scanning remote Google Drive folder ID: $folderId',
      );
      final remoteFiles = await _driveService.listFilesRecursively(
        accessToken,
        folderId,
      );
      AppLogger.i(
        '[SYNC_ENGINE] Remote scan found ${remoteFiles.length} files: ${remoteFiles.map((f) => f.relativePath).toList()}',
      );
      AppLogger.d('[SYNC_ENGINE] Scanning local folder: ${task.localPath}');
      final localFiles = await _localFileService.listFilesRecursively(
        task.localPath,
      );
      AppLogger.i(
        '[SYNC_ENGINE] Local scan found ${localFiles.length} files: ${localFiles.map((f) => f.relativePath).toList()}',
      );

      final remoteMap = {for (var f in remoteFiles) f.relativePath: f};
      final localMap = {for (var f in localFiles) f.relativePath: f};

      AppLogger.d('[SYNC_ENGINE] Loading previous sync state snapshot...');
      final lastState = await _stateRepository.getSnapshot(task.id);

      AppLogger.d(
        '[SYNC_ENGINE] Computing deltas and determining LWW resolution...',
      );
      final stateMap = Map<String, FileSnapshot>.from(lastState?.files ?? {});

      final actions = _computeSyncActions(
        localMap: localMap,
        remoteMap: remoteMap,
        stateMap: stateMap,
      );

      AppLogger.i(
        '[SYNC_ENGINE] Delta calculation complete. Required actions: ${actions.length}',
      );

      int completedActions = 0;
      await _taskRepository.updateTask(
        syncingTask.copyWith(filesRemaining: actions.length),
      );

      for (final action in actions) {
        try {
          switch (action.type) {
            case SyncActionType.upload:
              AppLogger.d(
                '[SYNC_ENGINE] Executing Upload: ${action.relativePath}',
              );
              final localFile = File(action.localFile!.absolutePath);
              final uploadedRemoteItem = await _driveService.uploadFile(
                accessToken,
                task.remotePath, // use the folder ID directly
                action.relativePath,
                localFile,
              );
              // Update state map
              stateMap[action.relativePath] = FileSnapshot(
                relativePath: action.relativePath,
                remoteId: uploadedRemoteItem.id,
                localModifiedTime: action.localFile!.modifiedTime,
                remoteModifiedTime: uploadedRemoteItem.modifiedTime,
                size: uploadedRemoteItem.size,
              );
              break;

            case SyncActionType.download:
              AppLogger.d(
                '[SYNC_ENGINE] Executing Download: ${action.relativePath}',
              );
              // Reconstruct full local absolute path
              final localAbsolutePath = p
                  .join(task.localPath, action.relativePath)
                  .replaceAll(r'\', '/');
              await _driveService.downloadFile(
                accessToken,
                action.remoteFile!.id,
                localAbsolutePath,
              );
              // Get new local stats
              final fileStat = await File(localAbsolutePath).stat();
              stateMap[action.relativePath] = FileSnapshot(
                relativePath: action.relativePath,
                remoteId: action.remoteFile!.id,
                localModifiedTime: fileStat.modified.toUtc(),
                remoteModifiedTime: action.remoteFile!.modifiedTime,
                size: action.remoteFile!.size,
              );
              break;

            case SyncActionType.deleteLocal:
              AppLogger.d(
                '[SYNC_ENGINE] Executing Delete Local: ${action.relativePath}',
              );
              await _localFileService.deleteFile(
                action.localFile!.absolutePath,
              );
              stateMap.remove(action.relativePath);
              break;

            case SyncActionType.deleteRemote:
              AppLogger.d(
                '[SYNC_ENGINE] Executing Delete Remote: ${action.relativePath}',
              );
              await _driveService.deleteFile(
                accessToken,
                action.remoteFile!.id,
              );
              stateMap.remove(action.relativePath);
              break;
          }
          completedActions++;

          await _taskRepository.updateTask(
            syncingTask.copyWith(
              progress:
                  completedActions / (actions.isEmpty ? 1 : actions.length),
              filesRemaining: actions.length - completedActions,
            ),
          );
        } catch (e) {
          AppLogger.w(
            '[SYNC_ENGINE] Action failed for ${action.relativePath}: $e',
          );
          // Important: We continue with the other actions so a single failure doesn't block the whole sync
        }
      }

      AppLogger.d('[SYNC_ENGINE] Persisting new state snapshot map...');
      await _stateRepository.saveSnapshot(
        SyncStateSnapshot(
          taskId: task.id,
          syncTimestamp: DateTime.now().toUtc(),
          files: stateMap,
        ),
      );

      // Record History
      await _historyRepository.addEntry(
        SyncHistoryEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          taskId: task.id,
          taskName: task.name,
          timestamp: DateTime.now(),
          status: SyncHistoryStatus.success,
          filesSynced: completedActions,
          totalFiles: actions.length,
          bytesTransferred: 0,
          errorMessage: null,
        ),
      );

      // Mark success
      final completedTask = syncingTask.copyWith(
        status: SyncTaskStatus.upToDate,
        progress: 1.0,
        filesRemaining: 0,
        lastSyncedAt: DateTime.now(),
      );
      await _taskRepository.updateTask(completedTask);
      AppLogger.i(
        '[SYNC_ENGINE] Sync finished successfully for task: ${task.id}',
      );
    } catch (e, stack) {
      AppLogger.e(
        '[SYNC_ENGINE] Sync failed for task ${task.id}: $e',
        error: e,
        stackTrace: stack,
      );

      // Record failed history
      await _historyRepository.addEntry(
        SyncHistoryEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          taskId: task.id,
          taskName: task.name,
          timestamp: DateTime.now(),
          status: SyncHistoryStatus.failed,
          filesSynced: 0,
          totalFiles: 0,
          bytesTransferred: 0,
          errorMessage: e.toString(),
        ),
      );

      // Mark error
      final failedTask = syncingTask.copyWith(
        status: SyncTaskStatus.error,
        errorMessage: e.toString(),
        progress: 0.0,
        filesRemaining: null,
      );
      await _taskRepository.updateTask(failedTask);
    }
  }

  /// Calculates the delta between Local, Remote, and Last Sync State.
  /// Determines actions based on Last-Write-Wins (LWW).
  List<SyncAction> _computeSyncActions({
    required Map<String, LocalFileItem> localMap,
    required Map<String, DriveFileItem> remoteMap,
    required Map<String, FileSnapshot> stateMap,
  }) {
    final List<SyncAction> actions = [];
    final allPaths = {...localMap.keys, ...remoteMap.keys, ...stateMap.keys};

    for (final path in allPaths) {
      final local = localMap[path];
      final remote = remoteMap[path];
      final state = stateMap[path];

      if (local == null && remote == null) {
        // Exists in state, but deleted from BOTH local and remote. No action needed.
        continue;
      }

      if (state == null) {
        // FILE IS BRAND NEW (Never synced before)
        if (local != null && remote != null) {
          // Exists on both sides, never synced. Conflict! Use LWW.
          if (local.modifiedTime.isAfter(remote.modifiedTime)) {
            actions.add(
              SyncAction(
                type: SyncActionType.upload,
                relativePath: path,
                localFile: local,
                remoteFile: remote,
              ),
            );
          } else {
            actions.add(
              SyncAction(
                type: SyncActionType.download,
                relativePath: path,
                localFile: local,
                remoteFile: remote,
              ),
            );
          }
        } else if (local != null) {
          // Only local
          actions.add(
            SyncAction(
              type: SyncActionType.upload,
              relativePath: path,
              localFile: local,
            ),
          );
        } else if (remote != null) {
          // Only remote
          actions.add(
            SyncAction(
              type: SyncActionType.download,
              relativePath: path,
              remoteFile: remote,
            ),
          );
        }
        continue;
      }

      // FILE WAS PREVIOUSLY SYNCED
      final localChanged =
          local != null && local.modifiedTime.isAfter(state.localModifiedTime);
      final remoteChanged =
          remote != null &&
          remote.modifiedTime.isAfter(state.remoteModifiedTime);

      if (local == null) {
        // Deleted locally.
        if (remoteChanged) {
          // Remote was updated since last sync, but user deleted it locally.
          // Safety: re-download the remote file instead of deleting the new changes.
          actions.add(
            SyncAction(
              type: SyncActionType.download,
              relativePath: path,
              remoteFile: remote,
            ),
          );
        } else {
          // Remote hasn't changed. Delete it remotely to mirror the local deletion.
          if (remote != null) {
            actions.add(
              SyncAction(
                type: SyncActionType.deleteRemote,
                relativePath: path,
                remoteFile: remote,
              ),
            );
          }
        }
        continue;
      }

      if (remote == null) {
        // Deleted remotely.
        if (localChanged) {
          // Local was updated since last sync, but deleted remotely.
          // Safety: re-upload the local changes.
          actions.add(
            SyncAction(
              type: SyncActionType.upload,
              relativePath: path,
              localFile: local,
            ),
          );
        } else {
          // Local hasn't changed. Delete it locally to mirror the remote deletion.
          actions.add(
            SyncAction(
              type: SyncActionType.deleteLocal,
              relativePath: path,
              localFile: local,
            ),
          );
        }
        continue;
      }

      // Exists on both sides. Check for changes.
      if (localChanged && remoteChanged) {
        // CONFLICT! Modified on both sides. Apply LWW.
        if (local.modifiedTime.isAfter(remote.modifiedTime)) {
          actions.add(
            SyncAction(
              type: SyncActionType.upload,
              relativePath: path,
              localFile: local,
              remoteFile: remote,
            ),
          );
        } else {
          actions.add(
            SyncAction(
              type: SyncActionType.download,
              relativePath: path,
              localFile: local,
              remoteFile: remote,
            ),
          );
        }
      } else if (localChanged && !remoteChanged) {
        actions.add(
          SyncAction(
            type: SyncActionType.upload,
            relativePath: path,
            localFile: local,
            remoteFile: remote,
          ),
        );
      } else if (!localChanged && remoteChanged) {
        actions.add(
          SyncAction(
            type: SyncActionType.download,
            relativePath: path,
            localFile: local,
            remoteFile: remote,
          ),
        );
      }
      // If neither changed (!localChanged && !remoteChanged), do nothing.
    }

    return actions;
  }
}

enum SyncActionType { upload, download, deleteLocal, deleteRemote }

class SyncAction {
  final SyncActionType type;
  final String relativePath;
  final LocalFileItem? localFile;
  final DriveFileItem? remoteFile;

  SyncAction({
    required this.type,
    required this.relativePath,
    this.localFile,
    this.remoteFile,
  });

  @override
  String toString() => 'SyncAction(type: $type, path: $relativePath)';
}
