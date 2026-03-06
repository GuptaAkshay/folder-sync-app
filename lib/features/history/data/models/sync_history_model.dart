import 'dart:convert';

import '../../domain/entities/sync_history_entry.dart';

/// Hive-compatible model for SyncHistoryEntry.
class SyncHistoryModel {
  const SyncHistoryModel({
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
  final String status;
  final int filesSynced;
  final int totalFiles;
  final String? errorMessage;
  final int? bytesTransferred;

  factory SyncHistoryModel.fromEntity(SyncHistoryEntry entry) {
    return SyncHistoryModel(
      id: entry.id,
      taskId: entry.taskId,
      taskName: entry.taskName,
      timestamp: entry.timestamp,
      status: entry.status.name,
      filesSynced: entry.filesSynced,
      totalFiles: entry.totalFiles,
      errorMessage: entry.errorMessage,
      bytesTransferred: entry.bytesTransferred,
    );
  }

  SyncHistoryEntry toEntity() {
    return SyncHistoryEntry(
      id: id,
      taskId: taskId,
      taskName: taskName,
      timestamp: timestamp,
      status: SyncHistoryStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => SyncHistoryStatus.success,
      ),
      filesSynced: filesSynced,
      totalFiles: totalFiles,
      errorMessage: errorMessage,
      bytesTransferred: bytesTransferred,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'taskId': taskId,
    'taskName': taskName,
    'timestamp': timestamp.toIso8601String(),
    'status': status,
    'filesSynced': filesSynced,
    'totalFiles': totalFiles,
    'errorMessage': errorMessage,
    'bytesTransferred': bytesTransferred,
  };

  factory SyncHistoryModel.fromJson(Map<String, dynamic> json) {
    return SyncHistoryModel(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      taskName: json['taskName'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: json['status'] as String,
      filesSynced: json['filesSynced'] as int? ?? 0,
      totalFiles: json['totalFiles'] as int? ?? 0,
      errorMessage: json['errorMessage'] as String?,
      bytesTransferred: json['bytesTransferred'] as int?,
    );
  }

  String encode() => jsonEncode(toJson());

  static SyncHistoryModel decode(String encoded) =>
      SyncHistoryModel.fromJson(jsonDecode(encoded) as Map<String, dynamic>);
}
