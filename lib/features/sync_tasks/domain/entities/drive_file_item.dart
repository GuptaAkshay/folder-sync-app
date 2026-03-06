/// A simplifed representation of a remote file found in Google Drive during directory scanning.
class DriveFileItem {
  const DriveFileItem({
    required this.id,
    required this.relativePath,
    required this.modifiedTime,
    required this.size,
  });

  /// The unique Google Drive file ID.
  final String id;

  /// The relative path mapping from the root sync folder (e.g., 'subfolder/file.txt').
  final String relativePath;

  /// The official 'modifiedTime' returned by the Google Drive API in UTC.
  final DateTime modifiedTime;

  /// The size of the file in bytes.
  final int size;
}
