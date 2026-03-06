import 'dart:convert';

import '../../domain/entities/sync_task.dart';

/// Hive model for SyncTask persistence.
///
/// We use manual JSON serialization instead of Hive type adapters
/// to avoid the hive_generator / freezed source_gen conflict.
class SyncTaskModel {
  const SyncTaskModel({
    required this.id,
    required this.name,
    required this.remotePath,
    required this.remoteFolderName,
    required this.localPath,
    required this.syncFrequency,
    required this.isTwoWaySync,
    required this.status,
    this.progress,
    this.filesRemaining,
    this.errorMessage,
    this.lastSyncedAt,
    this.createdAt,
  });

  final String id;
  final String name;
  final String remotePath;
  final String remoteFolderName;
  final String localPath;
  final String syncFrequency;
  final bool isTwoWaySync;
  final String status;
  final double? progress;
  final int? filesRemaining;
  final String? errorMessage;
  final DateTime? lastSyncedAt;
  final DateTime? createdAt;

  /// Convert from domain entity.
  factory SyncTaskModel.fromEntity(SyncTask task) {
    return SyncTaskModel(
      id: task.id,
      name: task.name,
      remotePath: task.remotePath,
      remoteFolderName: task.remoteFolderName,
      localPath: task.localPath,
      syncFrequency: task.syncFrequency.name,
      isTwoWaySync: task.isTwoWaySync,
      status: task.status.name,
      progress: task.progress,
      filesRemaining: task.filesRemaining,
      errorMessage: task.errorMessage,
      lastSyncedAt: task.lastSyncedAt,
      createdAt: task.createdAt,
    );
  }

  /// Convert to domain entity.
  SyncTask toEntity() {
    return SyncTask(
      id: id,
      name: name,
      remotePath: remotePath,
      remoteFolderName: remoteFolderName,
      localPath: localPath,
      syncFrequency: SyncFrequency.values.firstWhere(
        (e) => e.name == syncFrequency,
        orElse: () => SyncFrequency.onChange,
      ),
      isTwoWaySync: isTwoWaySync,
      status: SyncTaskStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => SyncTaskStatus.idle,
      ),
      progress: progress,
      filesRemaining: filesRemaining,
      errorMessage: errorMessage,
      lastSyncedAt: lastSyncedAt,
      createdAt: createdAt,
    );
  }

  /// Serialize to JSON map for Hive storage.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'remotePath': remotePath,
    'remoteFolderName': remoteFolderName,
    'localPath': localPath,
    'syncFrequency': syncFrequency,
    'isTwoWaySync': isTwoWaySync,
    'status': status,
    'progress': progress,
    'filesRemaining': filesRemaining,
    'errorMessage': errorMessage,
    'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
  };

  /// Deserialize from JSON map.
  factory SyncTaskModel.fromJson(Map<String, dynamic> json) {
    return SyncTaskModel(
      id: json['id'] as String,
      name: json['name'] as String,
      remotePath: json['remotePath'] as String,
      remoteFolderName:
          json['remoteFolderName'] as String? ?? 'Google Drive Folder',
      localPath: json['localPath'] as String,
      syncFrequency: json['syncFrequency'] as String,
      isTwoWaySync: json['isTwoWaySync'] as bool,
      status: json['status'] as String,
      progress: json['progress'] as double?,
      filesRemaining: json['filesRemaining'] as int?,
      errorMessage: json['errorMessage'] as String?,
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.parse(json['lastSyncedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  /// Encode to a string for Hive box storage.
  String encode() => jsonEncode(toJson());

  /// Decode from a Hive box string.
  static SyncTaskModel decode(String encoded) =>
      SyncTaskModel.fromJson(jsonDecode(encoded) as Map<String, dynamic>);
}
