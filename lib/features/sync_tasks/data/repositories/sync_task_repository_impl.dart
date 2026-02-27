import 'dart:async';

import 'package:hive/hive.dart';

import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/sync_task.dart';
import '../../domain/repositories/sync_task_repository.dart';
import '../models/sync_task_model.dart';

/// Hive-backed implementation of [SyncTaskRepository].
class SyncTaskRepositoryImpl implements SyncTaskRepository {
  SyncTaskRepositoryImpl({required this.box});

  final Box<String> box;

  /// Internal stream controller for broadcasting task changes.
  final _controller = StreamController<List<SyncTask>>.broadcast();

  void _notifyListeners() {
    getAllTasks().then(_controller.add);
  }

  @override
  Future<List<SyncTask>> getAllTasks() async {
    return box.values
        .map((encoded) => SyncTaskModel.decode(encoded).toEntity())
        .toList()
      ..sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
  }

  @override
  Future<SyncTask?> getTaskById(String id) async {
    final encoded = box.get(id);
    if (encoded == null) return null;
    return SyncTaskModel.decode(encoded).toEntity();
  }

  @override
  Future<SyncTask> createTask(SyncTask task) async {
    final now = DateTime.now();
    final newTask = task.copyWith(
      id: now.millisecondsSinceEpoch.toString(),
      createdAt: now,
      status: SyncTaskStatus.idle,
    );
    final model = SyncTaskModel.fromEntity(newTask);
    await box.put(newTask.id, model.encode());
    AppLogger.i('[SYNC_TASK] Created task: ${newTask.name} (${newTask.id})');
    _notifyListeners();
    return newTask;
  }

  @override
  Future<SyncTask> updateTask(SyncTask task) async {
    final model = SyncTaskModel.fromEntity(task);
    await box.put(task.id, model.encode());
    AppLogger.d('[SYNC_TASK] Updated task: ${task.name} (${task.id})');
    _notifyListeners();
    return task;
  }

  @override
  Future<void> deleteTask(String id) async {
    await box.delete(id);
    AppLogger.i('[SYNC_TASK] Deleted task: $id');
    _notifyListeners();
  }

  @override
  Stream<List<SyncTask>> watchAllTasks() {
    // Emit current state immediately, then stream updates
    getAllTasks().then(_controller.add);
    return _controller.stream;
  }
}
