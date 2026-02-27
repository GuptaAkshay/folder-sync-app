import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

/// Use case: Sign in with Google (FR-0a).
class SignIn {
  const SignIn(this._repository);
  final AuthRepository _repository;

  Future<AuthUser> call() => _repository.signIn();
}

/// Use case: Sign out and clear tokens.
class SignOut {
  const SignOut(this._repository);
  final AuthRepository _repository;

  Future<void> call() => _repository.signOut();
}

/// Use case: Get current authenticated user.
class GetCurrentUser {
  const GetCurrentUser(this._repository);
  final AuthRepository _repository;

  Future<AuthUser?> call() => _repository.getCurrentUser();
}

/// Use case: Attempt silent token refresh (FR-0c).
class SilentRefresh {
  const SilentRefresh(this._repository);
  final AuthRepository _repository;

  Future<bool> call() => _repository.silentRefresh();
}
