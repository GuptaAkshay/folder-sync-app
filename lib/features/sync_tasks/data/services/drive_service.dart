import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;

import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/drive_folder.dart';
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
}
