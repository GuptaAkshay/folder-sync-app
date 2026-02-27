/// Base failure class for the domain layer.
///
/// All feature-specific failures extend this class.
/// This allows use-cases and providers to handle errors
/// uniformly without depending on data-layer exceptions.
sealed class Failure {
  const Failure(this.message);
  final String message;

  @override
  String toString() => 'Failure: $message';
}

/// Authentication-related failures.
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Google Drive API failures.
class DriveFailure extends Failure {
  const DriveFailure(super.message);
}

/// Local storage / file system failures.
class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

/// Sync operation failures.
class SyncFailure extends Failure {
  const SyncFailure(super.message);
}
