/// Represents a single file sync event in the history (FR-4).
class SyncHistoryEntry {
  const SyncHistoryEntry({
    required this.id,
    required this.fileName,
    required this.taskName,
    required this.taskId,
    required this.timestamp,
    required this.status,
    this.errorMessage,
    this.fileSize,
  });

  final String id;
  final String fileName;
  final String taskName;
  final String taskId;
  final DateTime timestamp;
  final SyncHistoryStatus status;
  final String? errorMessage;

  /// File size in bytes, if available.
  final int? fileSize;

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
      'SyncHistoryEntry(file: $fileName, task: $taskName, status: $status)';
}

/// Status of a sync history entry.
enum SyncHistoryStatus {
  success('Success'),
  failed('Failed');

  const SyncHistoryStatus(this.label);
  final String label;
}
