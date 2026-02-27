/// Represents an authenticated user in the domain layer.
///
/// This is a pure domain entity — no framework or data-layer dependencies.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.accessToken,
  });

  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;

  /// OAuth access token for Google Drive API calls.
  /// Null if the user is not authenticated.
  final String? accessToken;

  bool get isAuthenticated => accessToken != null;

  AuthUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? accessToken,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      accessToken: accessToken ?? this.accessToken,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ email.hashCode;

  @override
  String toString() => 'AuthUser(id: $id, email: $email, name: $displayName)';
}
