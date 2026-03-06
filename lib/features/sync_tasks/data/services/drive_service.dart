import 'dart:io';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;

import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/drive_folder.dart';
import '../../domain/entities/drive_file_item.dart';
import '../../domain/entities/drive_storage_info.dart';

/// Service for interacting with the Google Drive API.
///
/// Currently provides storage quota information.
/// Will be extended with folder browsing, file sync, etc.
class DriveService {
  /// Bytes-to-GB divisor.
  static const double _bytesToGb = 1024 * 1024 * 1024;

  /// Fetches Drive storage quota for the authenticated user.
  ///
  /// Returns `null` if the quota cannot be retrieved.
  Future<DriveStorageInfo?> getStorageQuota(String accessToken) async {
    final client = authenticatedClient(
      http.Client(),
      AccessCredentials(
        AccessToken(
          'Bearer',
          accessToken,
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
        null, // no refresh token needed for single request
        [], // scopes already granted
      ),
    );

    try {
      AppLogger.d('[DRIVE] Fetching storage quota...');
      final driveApi = drive.DriveApi(client);
      final about = await driveApi.about.get($fields: 'storageQuota');

      final quota = about.storageQuota;
      if (quota == null) {
        AppLogger.w('[DRIVE] Storage quota returned null');
        return null;
      }

      final usageBytes = int.tryParse(quota.usage ?? '0') ?? 0;
      final limitBytes = int.tryParse(quota.limit ?? '0') ?? 0;

      AppLogger.d(
        '[DRIVE] Quota fetched successfully (${usageBytes}B used of ${limitBytes}B limit)',
      );
      return DriveStorageInfo(
        usedGb: usageBytes / _bytesToGb,
        totalGb: limitBytes > 0 ? limitBytes / _bytesToGb : 15.0,
      );
    } catch (e) {
      AppLogger.e('[DRIVE] Failed to fetch storage quota: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Fetches folders from Google Drive, optionally under a specific parent folder.
  /// If parentId is null, fetches folders from the root directory.
  Future<List<DriveFolder>> listFolders(
    String accessToken, {
    String? parentId,
  }) async {
    final client = authenticatedClient(
      http.Client(),
      AccessCredentials(
        AccessToken(
          'Bearer',
          accessToken,
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
        null,
        [],
      ),
    );

    try {
      AppLogger.d('[DRIVE] listFolders called with parentId: $parentId');
      final driveApi = drive.DriveApi(client);

      // Build the query: not trashed
      String query = "trashed=false";

      // If parentId is provided, filter by it; otherwise, default to 'root'
      if (parentId != null) {
        query += " and '$parentId' in parents";
      } else {
        query += " and 'root' in parents";
      }

      AppLogger.d('[DRIVE] Executing files.list with query: $query');
      final fileList = await driveApi.files.list(
        q: query,
        $fields: 'files(id, name, mimeType)',
        orderBy: 'folder, name',
        supportsAllDrives: true,
        includeItemsFromAllDrives: true,
      );

      final folders = (fileList.files ?? [])
          .where((file) => file.id != null && file.name != null)
          .map(
            (file) => DriveFolder(
              id: file.id!,
              name: file.name!,
              mimeType: file.mimeType,
            ),
          )
          .toList();

      AppLogger.d('[DRIVE] Found ${folders.length} folders');
      return folders;
    } catch (e, stack) {
      AppLogger.e(
        '[DRIVE] Failed to list folders: $e',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Recursively lists all non-folder files within a given [rootFolderId] in Google Drive.
  /// Builds relative paths for each file mapping back to the root folder.
  /// Used by the sync engine to create a snapshot of the remote state.
  Future<List<DriveFileItem>> listFilesRecursively(
    String accessToken,
    String rootFolderId,
  ) async {
    final client = authenticatedClient(
      http.Client(),
      AccessCredentials(
        AccessToken(
          'Bearer',
          accessToken,
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
        null,
        [],
      ),
    );

    try {
      AppLogger.d(
        '[DRIVE] Starting recursive file scan for root folder: $rootFolderId',
      );
      final driveApi = drive.DriveApi(client);

      final List<DriveFileItem> allFiles = [];

      // Queue of folders to process: pairs of (FolderId, RelativePathToFolder)
      final List<MapEntry<String, String>> folderQueue = [
        MapEntry(rootFolderId, ''),
      ];

      while (folderQueue.isNotEmpty) {
        final currentFolder = folderQueue.removeAt(0);
        final folderId = currentFolder.key;
        final currentPath = currentFolder.value;

        String? pageToken;
        do {
          final String query = "'$folderId' in parents and trashed=false";
          final fileList = await driveApi.files.list(
            q: query,
            $fields:
                'nextPageToken, files(id, name, mimeType, modifiedTime, size)',
            pageToken: pageToken,
            supportsAllDrives: true,
            includeItemsFromAllDrives: true,
          );

          if (fileList.files != null) {
            for (final file in fileList.files!) {
              if (file.id == null || file.name == null) continue;

              final isFolder =
                  file.mimeType == 'application/vnd.google-apps.folder';

              if (isFolder) {
                // Determine path: if current path is empty, it's just the folder name. Otherwise append.
                final newPath = currentPath.isEmpty
                    ? file.name!
                    : '$currentPath/${file.name}';
                folderQueue.add(MapEntry(file.id!, newPath));
              } else {
                // It's a regular file
                final filePath = currentPath.isEmpty
                    ? file.name!
                    : '$currentPath/${file.name}';

                final size = int.tryParse(file.size ?? '0') ?? 0;
                final modifiedTime =
                    file.modifiedTime ?? DateTime.now().toUtc();

                allFiles.add(
                  DriveFileItem(
                    id: file.id!,
                    relativePath: filePath,
                    modifiedTime: modifiedTime,
                    size: size,
                  ),
                );
              }
            }
          }

          pageToken = fileList.nextPageToken;
        } while (pageToken != null);
      }

      AppLogger.d(
        '[DRIVE] Recursive scan complete. Found ${allFiles.length} files under root folder.',
      );
      return allFiles;
    } catch (e, stack) {
      AppLogger.e(
        '[DRIVE] Exception during recursive file scan: $e',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Downloads a file from Google Drive and saves it to the specified [localAbsolutePath].
  Future<void> downloadFile(
    String accessToken,
    String fileId,
    String localAbsolutePath,
  ) async {
    final client = authenticatedClient(
      http.Client(),
      AccessCredentials(
        AccessToken(
          'Bearer',
          accessToken,
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
        null,
        [],
      ),
    );

    try {
      final driveApi = drive.DriveApi(client);
      final media =
          await driveApi.files.get(
                fileId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;

      final localFile = File(localAbsolutePath);
      final parentDir = localFile.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }

      final ios = localFile.openWrite();
      await media.stream.pipe(ios);
      await ios.flush();
      await ios.close();

      AppLogger.d('[DRIVE] Successfully downloaded file to $localAbsolutePath');
    } catch (e, stack) {
      AppLogger.e(
        '[DRIVE] Failed to download file $fileId: $e',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Deletes a file or folder from Google Drive by its [fileId].
  Future<void> deleteFile(String accessToken, String fileId) async {
    final client = authenticatedClient(
      http.Client(),
      AccessCredentials(
        AccessToken(
          'Bearer',
          accessToken,
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
        null,
        [],
      ),
    );

    try {
      final driveApi = drive.DriveApi(client);
      await driveApi.files.delete(fileId);
      AppLogger.d('[DRIVE] Successfully deleted remote file $fileId');
    } catch (e, stack) {
      AppLogger.e(
        '[DRIVE] Failed to delete file $fileId: $e',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Uploads a local file to Google Drive, recreating any necessary nested sub-folders.
  /// [rootFolderId] is the base sync folder on Drive.
  /// [relativePath] is relative to the root folder (e.g., 'Documents/budget.xlsx').
  Future<DriveFileItem> uploadFile(
    String accessToken,
    String rootFolderId,
    String relativePath,
    File localFile,
  ) async {
    final client = authenticatedClient(
      http.Client(),
      AccessCredentials(
        AccessToken(
          'Bearer',
          accessToken,
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
        null,
        [],
      ),
    );

    try {
      final driveApi = drive.DriveApi(client);

      // Split path into folders and filename
      final pathSegments = relativePath.split('/');
      final fileName = pathSegments.removeLast();

      // Ensure all parent directories exist in Drive before uploading the file
      final targetParentId = await _ensureFolderHierarchy(
        driveApi,
        rootFolderId,
        pathSegments,
      );

      // Create new file metadata
      final fileMetadata = drive.File()
        ..name = fileName
        ..parents = [targetParentId];

      final stat = await localFile.stat();
      fileMetadata.modifiedTime = stat.modified.toUtc();

      final fileStream = localFile.openRead();
      final length = await localFile.length();
      final media = drive.Media(fileStream, length);

      AppLogger.d(
        '[DRIVE] Uploading file $fileName (size: $length bytes) to parent $targetParentId',
      );
      final uploadedFile = await driveApi.files.create(
        fileMetadata,
        uploadMedia: media,
        $fields: 'id, name, modifiedTime, size',
      );

      final size = int.tryParse(uploadedFile.size ?? '0') ?? 0;
      final modifiedTime = uploadedFile.modifiedTime ?? DateTime.now().toUtc();

      return DriveFileItem(
        id: uploadedFile.id!,
        relativePath: relativePath,
        modifiedTime: modifiedTime,
        size: size,
      );
    } catch (e, stack) {
      AppLogger.e(
        '[DRIVE] Failed to upload file $relativePath: $e',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Helper to traverse and/or create a sequence of nested folders.
  /// Returns the ID of the innermost folder.
  Future<String> _ensureFolderHierarchy(
    drive.DriveApi driveApi,
    String currentParentId,
    List<String> folderNames,
  ) async {
    String parentId = currentParentId;

    for (final folderName in folderNames) {
      // Check if folder exists in current parent
      final query =
          "'$parentId' in parents and name='$folderName' and mimeType='application/vnd.google-apps.folder' and trashed=false";
      final fileList = await driveApi.files.list(
        q: query,
        $fields: 'files(id)',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        // Folder exists! Move down.
        parentId = fileList.files!.first.id!;
      } else {
        // Folder does not exist, create it.
        AppLogger.d(
          '[DRIVE] Creating missing nested folder: $folderName in parent $parentId',
        );
        final newFolder = drive.File()
          ..name = folderName
          ..mimeType = 'application/vnd.google-apps.folder'
          ..parents = [parentId];

        final createdFolder = await driveApi.files.create(
          newFolder,
          $fields: 'id',
        );
        parentId = createdFolder.id!;
      }
    }

    return parentId;
  }
}
