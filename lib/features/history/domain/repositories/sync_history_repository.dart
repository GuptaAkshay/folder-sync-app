import '../entities/sync_history_entry.dart';

/// Abstract repository interface for sync history (FR-4).
abstract class SyncHistoryRepository {
  /// Get all history entries, ordered by most recent first.
  Future<List<SyncHistoryEntry>> getAllEntries();

  /// Add a new history entry.
  Future<void> addEntry(SyncHistoryEntry entry);

  /// Clear all history entries.
  Future<void> clearAll();

  /// Stream of history entries for real-time updates.
  Stream<List<SyncHistoryEntry>> watchAllEntries();
}
