import '../entities/sync_task.dart';
import '../repositories/sync_task_repository.dart';

/// Use case: Get all sync tasks for the dashboard (FR-1).
class GetAllSyncTasks {
  const GetAllSyncTasks(this._repository);
  final SyncTaskRepository _repository;

  Future<List<SyncTask>> call() => _repository.getAllTasks();
}

/// Use case: Watch all tasks as a stream (real-time updates).
class WatchAllSyncTasks {
  const WatchAllSyncTasks(this._repository);
  final SyncTaskRepository _repository;

  Stream<List<SyncTask>> call() => _repository.watchAllTasks();
}

/// Use case: Create a new sync task (FR-3).
class CreateSyncTask {
  const CreateSyncTask(this._repository);
  final SyncTaskRepository _repository;

  Future<SyncTask> call(SyncTask task) => _repository.createTask(task);
}

/// Use case: Update a sync task (FR-6).
class UpdateSyncTask {
  const UpdateSyncTask(this._repository);
  final SyncTaskRepository _repository;

  Future<SyncTask> call(SyncTask task) => _repository.updateTask(task);
}

/// Use case: Delete a sync task (FR-7).
class DeleteSyncTask {
  const DeleteSyncTask(this._repository);
  final SyncTaskRepository _repository;

  Future<void> call(String id) => _repository.deleteTask(id);
}
