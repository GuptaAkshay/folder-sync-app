import 'dart:async';

import 'package:hive/hive.dart';

import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/sync_history_entry.dart';
import '../../domain/repositories/sync_history_repository.dart';
import '../models/sync_history_model.dart';

/// Hive-backed implementation of [SyncHistoryRepository].
class SyncHistoryRepositoryImpl implements SyncHistoryRepository {
  SyncHistoryRepositoryImpl({required this.box});

  final Box<String> box;
  final _controller = StreamController<List<SyncHistoryEntry>>.broadcast();

  void _notifyListeners() {
    getAllEntries().then(_controller.add);
  }

  @override
  Future<List<SyncHistoryEntry>> getAllEntries() async {
    return box.values
        .map((encoded) => SyncHistoryModel.decode(encoded).toEntity())
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<void> addEntry(SyncHistoryEntry entry) async {
    final model = SyncHistoryModel.fromEntity(entry);
    await box.put(entry.id, model.encode());
    AppLogger.d('[HISTORY] Added entry: ${entry.id} (${entry.status.name})');
    _notifyListeners();
  }

  @override
  Future<void> clearAll() async {
    await box.clear();
    AppLogger.i('[HISTORY] Cleared all history entries');
    _notifyListeners();
  }

  @override
  Stream<List<SyncHistoryEntry>> watchAllEntries() {
    getAllEntries().then(_controller.add);
    return _controller.stream;
  }
}
