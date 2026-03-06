import 'dart:convert';

/// Represents a snapshot of a file's state during the last successful sync.
class FileSnapshot {
  const FileSnapshot({
    required this.relativePath,
    this.remoteId,
    required this.localModifiedTime,
    required this.remoteModifiedTime,
    required this.size,
  });

  /// The relative path of the file from the sync root (e.g., 'Documents/budget.xlsx').
  final String relativePath;

  /// The Google Drive file ID (useful for updates/deletions).
  final String? remoteId;

  /// The last modified time of the local file at the time of sync.
  final DateTime localModifiedTime;

  /// The last modified time of the remote Google Drive file at the time of sync.
  final DateTime remoteModifiedTime;

  /// The size of the file in bytes at the time of sync.
  final int size;

  Map<String, dynamic> toMap() {
    return {
      'relativePath': relativePath,
      'remoteId': remoteId,
      'localModifiedTime': localModifiedTime.toIso8601String(),
      'remoteModifiedTime': remoteModifiedTime.toIso8601String(),
      'size': size,
    };
  }

  factory FileSnapshot.fromMap(Map<String, dynamic> map) {
    return FileSnapshot(
      relativePath: map['relativePath'] as String,
      remoteId: map['remoteId'] != null ? map['remoteId'] as String : null,
      localModifiedTime: DateTime.parse(map['localModifiedTime'] as String),
      remoteModifiedTime: DateTime.parse(map['remoteModifiedTime'] as String),
      size: map['size'] as int,
    );
  }

  FileSnapshot copyWith({
    String? relativePath,
    String? remoteId,
    DateTime? localModifiedTime,
    DateTime? remoteModifiedTime,
    int? size,
  }) {
    return FileSnapshot(
      relativePath: relativePath ?? this.relativePath,
      remoteId: remoteId ?? this.remoteId,
      localModifiedTime: localModifiedTime ?? this.localModifiedTime,
      remoteModifiedTime: remoteModifiedTime ?? this.remoteModifiedTime,
      size: size ?? this.size,
    );
  }
}

/// Represents the state of a SyncTask at the completion of a sync cycle.
class SyncStateSnapshot {
  const SyncStateSnapshot({
    required this.taskId,
    required this.syncTimestamp,
    this.files = const {},
  });

  /// The ID of the SyncTask this state corresponds to.
  final String taskId;

  /// When this state was recorded.
  final DateTime syncTimestamp;

  /// The files present at the end of the last sync.
  /// Key: relativePath. Value: FileSnapshot.
  final Map<String, FileSnapshot> files;

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'syncTimestamp': syncTimestamp.toIso8601String(),
      'files': files.map((key, value) => MapEntry(key, value.toMap())),
    };
  }

  factory SyncStateSnapshot.fromMap(Map<String, dynamic> map) {
    final fileMap = (map['files'] as Map<String, dynamic>?) ?? {};
    return SyncStateSnapshot(
      taskId: map['taskId'] as String,
      syncTimestamp: DateTime.parse(map['syncTimestamp'] as String),
      files: fileMap.map(
        (key, value) =>
            MapEntry(key, FileSnapshot.fromMap(value as Map<String, dynamic>)),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory SyncStateSnapshot.fromJson(String source) =>
      SyncStateSnapshot.fromMap(json.decode(source) as Map<String, dynamic>);
}
