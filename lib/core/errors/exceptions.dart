// Custom exceptions for the data layer.
// These are thrown by data sources and caught by repositories,
// which convert them into Failure objects for the domain layer.

/// Exception thrown when authentication fails.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => 'AuthException: $message';
}

class DriveApiException implements Exception {
  const DriveApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'DriveApiException($statusCode): $message';
}

class StorageException implements Exception {
  const StorageException(this.message);
  final String message;

  @override
  String toString() => 'StorageException: $message';
}
