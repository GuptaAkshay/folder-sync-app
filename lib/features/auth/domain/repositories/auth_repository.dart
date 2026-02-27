import '../entities/auth_user.dart';

/// Abstract repository interface for authentication (FR-0a).
///
/// Domain layer defines this interface; data layer implements it.
/// This enables swapping out the auth provider without touching business logic.
abstract class AuthRepository {
  /// Sign in with Google. Returns the authenticated user.
  /// Throws [AuthFailure] on failure.
  Future<AuthUser> signIn();

  /// Sign out and clear all tokens.
  Future<void> signOut();

  /// Get the currently authenticated user, or null if not signed in.
  Future<AuthUser?> getCurrentUser();

  /// Attempt a silent token refresh.
  /// Returns true if refresh succeeded, false otherwise.
  Future<bool> silentRefresh();

  /// Stream of auth state changes.
  Stream<AuthUser?> get authStateChanges;
}
