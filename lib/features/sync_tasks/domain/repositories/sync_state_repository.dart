import '../entities/sync_state_snapshot.dart';

/// Repository for saving and loading the snapshot of a folder's state after a successful sync.
/// This prevents us from having to guess what was deleted vs what is brand new.
abstract class SyncStateRepository {
  /// Loads the last successful sync state for a given task ID.
  /// Returns null if this task has never been synced successfully.
  Future<SyncStateSnapshot?> getSnapshot(String taskId);

  /// Saves the snapshot for a given task ID. Overwrites any existing snapshot.
  Future<void> saveSnapshot(SyncStateSnapshot snapshot);

  /// Deletes the snapshot for a given task ID.
  Future<void> deleteSnapshot(String taskId);
}
