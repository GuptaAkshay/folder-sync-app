/// App-wide constants for FolderSync.
class AppConstants {
  AppConstants._();

  static const String appName = 'FolderSync';
  static const String appVersion = '0.1.0';

  /// Maximum number of file versions to retain per file.
  static const int maxVersionsPerFile = 10;

  /// Google Drive OAuth scopes.
  static const List<String> driveScopes = [
    'https://www.googleapis.com/auth/drive',
  ];
}
