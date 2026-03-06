/// Represents a single sync execution summary in the history (FR-4).
class SyncHistoryEntry {
  const SyncHistoryEntry({
    required this.id,
    required this.taskId,
    required this.taskName,
    required this.timestamp,
    required this.status,
    required this.filesSynced,
    required this.totalFiles,
    this.errorMessage,
    this.bytesTransferred,
  });

  final String id;
  final String taskId;
  final String taskName;
  final DateTime timestamp;
  final SyncHistoryStatus status;
  final int filesSynced;
  final int totalFiles;
  final String? errorMessage;
  final int? bytesTransferred;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncHistoryEntry &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SyncHistoryEntry(task: $taskName, files: $filesSynced/$totalFiles, status: $status)';
}

/// Status of a sync history entry.
enum SyncHistoryStatus {
  success('Success'),
  failed('Failed');

  const SyncHistoryStatus(this.label);
  final String label;
}
