import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/app_logger.dart';

/// A simplified representation of a local file found during directory scanning.
class LocalFileItem {
  LocalFileItem({
    required this.absolutePath,
    required this.relativePath,
    required this.modifiedTime,
    required this.size,
  });

  final String absolutePath;
  final String relativePath;
  final DateTime modifiedTime;
  final int size;
}

/// Service for interacting with the local Android file system.
class LocalFileService {
  /// Recursively lists all files in a given directory, returning a list of [LocalFileItem].
  /// [relativePath] is calculated relative to the provided [rootDirectoryPath].
  Future<List<LocalFileItem>> listFilesRecursively(
    String rootDirectoryPath,
  ) async {
    final rootDir = Directory(rootDirectoryPath);
    if (!await rootDir.exists()) {
      AppLogger.w(
        '[LOCAL_FILE_SERVICE] Root directory does not exist: $rootDirectoryPath',
      );
      return [];
    }

    final List<LocalFileItem> localFiles = [];
    try {
      // Log directory existence and stats for diagnostics
      final dirStat = await rootDir.stat();
      AppLogger.i(
        '[LOCAL_FILE_SERVICE] Scanning directory: $rootDirectoryPath | type: ${dirStat.type} | modified: ${dirStat.modified}',
      );

      // Use true for recursive to get all nested files
      final entities = rootDir.list(recursive: true, followLinks: false);

      await for (final entity in entities) {
        AppLogger.d(
          '[LOCAL_FILE_SERVICE] Found entity: ${entity.path} (${entity.runtimeType})',
        );
        if (entity is File) {
          try {
            final stat = await entity.stat();
            final absolutePath = entity.path;

            // Generate the relative path from the sync root path.
            // Replace backslashes with forward slashes for cross-platform consistency.
            final relativePath = p
                .relative(absolutePath, from: rootDirectoryPath)
                .replaceAll(r'\', '/');

            localFiles.add(
              LocalFileItem(
                absolutePath: absolutePath,
                relativePath: relativePath,
                // Converting to UTC to ensure fair comparison with Google Drive timestamps
                modifiedTime: stat.modified.toUtc(),
                size: stat.size,
              ),
            );
          } catch (e) {
            AppLogger.e(
              '[LOCAL_FILE_SERVICE] Error reading file stats for ${entity.path}: $e',
            );
            // Continue scanning even if one file fails
          }
        }
      }
    } catch (e) {
      AppLogger.e(
        '[LOCAL_FILE_SERVICE] Error during recursive directory scanning: $e',
      );
      rethrow;
    }

    AppLogger.d(
      '[LOCAL_FILE_SERVICE] Found ${localFiles.length} local files in $rootDirectoryPath',
    );
    return localFiles;
  }

  /// Copies a file from the [sourceAbsolutePath] to [destinationAbsolutePath].
  /// Creates the parent directories for the destination if they don't exist.
  Future<File> copyFile(
    String sourceAbsolutePath,
    String destinationAbsolutePath,
  ) async {
    final sourceFile = File(sourceAbsolutePath);
    final destinationFile = File(destinationAbsolutePath);

    // Ensure parent directories exist
    final parentDir = destinationFile.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }

    return await sourceFile.copy(destinationAbsolutePath);
  }

  /// Deletes a file at [absolutePath] if it exists.
  Future<void> deleteFile(String absolutePath) async {
    final file = File(absolutePath);
    if (await file.exists()) {
      await file.delete();
      AppLogger.d('[LOCAL_FILE_SERVICE] Deleted local file: $absolutePath');
    }
  }

  /// Checks if a file exists at the given [absolutePath].
  Future<bool> fileExists(String absolutePath) async {
    return await File(absolutePath).exists();
  }
}
