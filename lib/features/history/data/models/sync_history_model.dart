import 'dart:convert';

import '../../domain/entities/sync_history_entry.dart';

/// Hive-compatible model for SyncHistoryEntry.
class SyncHistoryModel {
  const SyncHistoryModel({
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
  final String status;
  final String? errorMessage;
  final int? fileSize;

  factory SyncHistoryModel.fromEntity(SyncHistoryEntry entry) {
    return SyncHistoryModel(
      id: entry.id,
      fileName: entry.fileName,
      taskName: entry.taskName,
      taskId: entry.taskId,
      timestamp: entry.timestamp,
      status: entry.status.name,
      errorMessage: entry.errorMessage,
      fileSize: entry.fileSize,
    );
  }

  SyncHistoryEntry toEntity() {
    return SyncHistoryEntry(
      id: id,
      fileName: fileName,
      taskName: taskName,
      taskId: taskId,
      timestamp: timestamp,
      status: SyncHistoryStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => SyncHistoryStatus.success,
      ),
      errorMessage: errorMessage,
      fileSize: fileSize,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileName': fileName,
    'taskName': taskName,
    'taskId': taskId,
    'timestamp': timestamp.toIso8601String(),
    'status': status,
    'errorMessage': errorMessage,
    'fileSize': fileSize,
  };

  factory SyncHistoryModel.fromJson(Map<String, dynamic> json) {
    return SyncHistoryModel(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      taskName: json['taskName'] as String,
      taskId: json['taskId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: json['status'] as String,
      errorMessage: json['errorMessage'] as String?,
      fileSize: json['fileSize'] as int?,
    );
  }

  String encode() => jsonEncode(toJson());

  static SyncHistoryModel decode(String encoded) =>
      SyncHistoryModel.fromJson(jsonDecode(encoded) as Map<String, dynamic>);
}
