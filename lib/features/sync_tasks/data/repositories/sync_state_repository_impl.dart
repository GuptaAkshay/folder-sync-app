import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/sync_state_snapshot.dart';
import '../../domain/repositories/sync_state_repository.dart';

class SyncStateRepositoryImpl implements SyncStateRepository {
  final Box<String> _box;

  SyncStateRepositoryImpl({required Box<String> box}) : _box = box;

  @override
  Future<SyncStateSnapshot?> getSnapshot(String taskId) async {
    final jsonString = _box.get(taskId);
    if (jsonString == null) return null;
    try {
      return SyncStateSnapshot.fromJson(jsonString);
    } catch (e) {
      // In case of parsing error, return null to force a fresh sync (safe fallback)
      return null;
    }
  }

  @override
  Future<void> saveSnapshot(SyncStateSnapshot snapshot) async {
    final jsonString = snapshot.toJson();
    await _box.put(snapshot.taskId, jsonString);
  }

  @override
  Future<void> deleteSnapshot(String taskId) async {
    await _box.delete(taskId);
  }
}
