import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Google Sign-In implementation of [AuthRepository].
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    GoogleSignIn? googleSignIn,
    FlutterSecureStorage? secureStorage,
  }) : _googleSignIn =
           googleSignIn ?? GoogleSignIn(scopes: AppConstants.driveScopes),
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final GoogleSignIn _googleSignIn;
  final FlutterSecureStorage _secureStorage;

  static const _tokenKey = 'google_access_token';
  static const _userKey = 'google_user_json';

  final _authStateController = StreamController<AuthUser?>.broadcast();

  @override
  Future<AuthUser> signIn() async {
    try {
      AppLogger.i('[AUTH] Starting Google Sign-In...');
      final account = await _googleSignIn.signIn();
      if (account == null) {
        AppLogger.i('[AUTH] Sign-in cancelled by user');
        throw const AuthException('Sign-in cancelled by user');
      }

      AppLogger.i('[AUTH] Sign-in successful for: ${account.email}');
      final auth = await account.authentication;
      AppLogger.d(
        '[AUTH] Got auth tokens, accessToken present: ${auth.accessToken != null}',
      );

      final user = AuthUser(
        id: account.id,
        email: account.email,
        displayName: account.displayName ?? account.email,
        photoUrl: account.photoUrl,
        accessToken: auth.accessToken,
      );

      // Persist token securely (non-fatal if it fails)
      if (auth.accessToken != null) {
        try {
          await _secureStorage.write(key: _tokenKey, value: auth.accessToken);
          AppLogger.d('[AUTH] Token persisted to secure storage');
        } catch (storageError) {
          AppLogger.e(
            '[AUTH] Warning: Failed to persist token to secure storage: $storageError',
          );
          // Continue — sign-in still succeeded, token is in memory
        }
      }

      _authStateController.add(user);
      AppLogger.i('[AUTH] Auth state updated, user signed in');
      return user;
    } catch (e) {
      AppLogger.e('[AUTH] Sign-in error: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Sign-in failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _userKey);
      _authStateController.add(null);
    } catch (e) {
      throw AuthException('Sign-out failed: $e');
    }
  }

  @override
  Future<AuthUser?> getCurrentUser() async {
    final account = _googleSignIn.currentUser;
    if (account == null) return null;

    final token = await _secureStorage.read(key: _tokenKey);
    return AuthUser(
      id: account.id,
      email: account.email,
      displayName: account.displayName ?? account.email,
      photoUrl: account.photoUrl,
      accessToken: token,
    );
  }

  @override
  Future<bool> silentRefresh() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) return false;

      final auth = await account.authentication;
      if (auth.accessToken == null) return false;

      await _secureStorage.write(key: _tokenKey, value: auth.accessToken);

      final user = AuthUser(
        id: account.id,
        email: account.email,
        displayName: account.displayName ?? account.email,
        photoUrl: account.photoUrl,
        accessToken: auth.accessToken,
      );
      _authStateController.add(user);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<AuthUser?> get authStateChanges => _authStateController.stream;
}
