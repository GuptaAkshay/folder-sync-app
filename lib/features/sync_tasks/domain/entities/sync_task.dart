/// Represents a sync task in the domain layer.
///
/// Each task pairs a remote Google Drive folder with a local Android folder.
class SyncTask {
  const SyncTask({
    required this.id,
    required this.name,
    required this.remotePath,
    required this.localPath,
    this.syncFrequency = SyncFrequency.onChange,
    this.isTwoWaySync = false,
    this.status = SyncTaskStatus.idle,
    this.progress,
    this.filesRemaining,
    this.errorMessage,
    this.lastSyncedAt,
    this.createdAt,
  });

  final String id;
  final String name;

  /// Google Drive folder path (e.g., "Google Drive /Photos").
  final String remotePath;

  /// Local Android folder path (e.g., "/DCIM/Camera").
  final String localPath;

  final SyncFrequency syncFrequency;
  final bool isTwoWaySync;
  final SyncTaskStatus status;

  /// 0.0 to 1.0 progress when status is [SyncTaskStatus.syncing].
  final double? progress;
  final int? filesRemaining;
  final String? errorMessage;
  final DateTime? lastSyncedAt;
  final DateTime? createdAt;

  SyncTask copyWith({
    String? id,
    String? name,
    String? remotePath,
    String? localPath,
    SyncFrequency? syncFrequency,
    bool? isTwoWaySync,
    SyncTaskStatus? status,
    double? progress,
    int? filesRemaining,
    String? errorMessage,
    DateTime? lastSyncedAt,
    DateTime? createdAt,
  }) {
    return SyncTask(
      id: id ?? this.id,
      name: name ?? this.name,
      remotePath: remotePath ?? this.remotePath,
      localPath: localPath ?? this.localPath,
      syncFrequency: syncFrequency ?? this.syncFrequency,
      isTwoWaySync: isTwoWaySync ?? this.isTwoWaySync,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      filesRemaining: filesRemaining ?? this.filesRemaining,
      errorMessage: errorMessage ?? this.errorMessage,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncTask && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SyncTask(id: $id, name: $name, status: $status)';
}

/// How often a sync task should run.
enum SyncFrequency {
  onChange('On Change'),
  hourly('Hourly'),
  daily('Daily');

  const SyncFrequency(this.label);
  final String label;
}

/// Current status of a sync task.
enum SyncTaskStatus {
  idle('Idle'),
  syncing('Syncing'),
  upToDate('Up to Date'),
  error('Error');

  const SyncTaskStatus(this.label);
  final String label;
}
