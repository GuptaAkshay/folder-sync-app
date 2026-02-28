/// Represents a Google Drive folder.
class DriveFolder {
  /// The unique ID of the folder in Google Drive.
  final String id;

  /// The specific name of the folder.
  final String name;

  /// The full path of the folder, used for display purposes.
  final String path;

  /// The MIME type, generally 'application/vnd.google-apps.folder'.
  final String? mimeType;

  const DriveFolder({
    required this.id,
    required this.name,
    String? path,
    this.mimeType,
  }) : path = path ?? name;
}
