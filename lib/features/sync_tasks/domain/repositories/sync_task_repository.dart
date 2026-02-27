import '../entities/sync_task.dart';

/// Abstract repository interface for sync tasks (FR-1, FR-3).
///
/// Domain layer defines this; data layer implements it.
abstract class SyncTaskRepository {
  /// Get all sync tasks.
  Future<List<SyncTask>> getAllTasks();

  /// Get a single sync task by ID.
  Future<SyncTask?> getTaskById(String id);

  /// Create a new sync task. Returns the created task with a generated ID.
  Future<SyncTask> createTask(SyncTask task);

  /// Update an existing sync task.
  Future<SyncTask> updateTask(SyncTask task);

  /// Delete a sync task by ID.
  Future<void> deleteTask(String id);

  /// Stream of all tasks (for real-time dashboard updates).
  Stream<List<SyncTask>> watchAllTasks();
}
