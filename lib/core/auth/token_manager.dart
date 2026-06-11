import 'package:datasolids_mobile/core/auth/auth_state.dart';
import 'package:datasolids_mobile/core/config/env.dart';
import 'package:datasolids_mobile/core/logging/logger.dart';
import 'package:datasolids_mobile/core/storage/secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

/// Owns the access/refresh token lifecycle.
///
/// Designed to be the ONLY place tokens leave or re-enter the keychain.
/// Feature code never touches `flutter_secure_storage` directly.
class TokenManager {
  TokenManager(this._ref);

  final Ref _ref;

  SecureStorage get _storage => _ref.read(secureStorageProvider);

  Future<String?> getAccessToken() async {
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty) return null;
    // Cheap, local-only expiry check. Real validity is decided by the
    // server on every call; this just lets us proactively refresh.
    if (JwtDecoder.isExpired(token)) {
      final refreshed = await refresh();
      if (!refreshed) return null;
      return _storage.readAccessToken();
    }
    return token;
  }

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await _storage.writeAccessToken(access);
    await _storage.writeRefreshToken(refresh);
    _ref.setAuthenticated(value: true);
  }

  Future<bool> refresh() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    final dio = Dio(BaseOptions(baseUrl: '${Env.instance.apiBaseUrl}/api/v1'));
    try {
      final resp = await dio.post<Map<String, dynamic>>(
        '/auth/token/refresh/',
        data: {'refresh': refreshToken},
      );
      final access = resp.data?['access'] as String?;
      final newRefresh = resp.data?['refresh'] as String?;
      if (access == null) return false;
      await _storage.writeAccessToken(access);
      if (newRefresh != null) {
        await _storage.writeRefreshToken(newRefresh);
      }
      return true;
    } catch (e, st) {
      appLogger.w('Refresh failed', error: e, stackTrace: st);
      return false;
    }
  }

  Future<void> signOut({String reason = 'user_signed_out'}) async {
    appLogger.i('Signing out: $reason');
    await _storage.clearAll();
    _ref.setAuthenticated(value: false);
  }

  /// Call from bootstrap once the app first frames — warms the router's
  /// `authStateProvider` from the keychain so we don't flash /login
  /// for a returning signed-in user.
  ///
  /// Logic:
  ///   1. If the access token in the keychain is still valid → signed in.
  ///   2. If access is expired but a refresh token exists → try refreshing
  ///      against the backend. If that succeeds we stay signed in; if it
  ///      fails (refresh expired, revoked, or password changed since)
  ///      we wipe the keychain and the router takes them to /login.
  ///   3. If neither token exists → signed out.
  ///
  /// This is what makes "close app → reopen later → still signed in"
  /// work. Access tokens are short-lived (15min) — without the refresh
  /// fallback every reopen after lunch would land on /login.
  Future<void> warmFromStorage() async {
    final access = await _storage.readAccessToken();
    if (access != null && access.isNotEmpty &&
        !JwtDecoder.isExpired(access)) {
      _ref.setAuthenticated(value: true);
      return;
    }

    // Access is missing or stale — try to revive the session from the
    // long-lived refresh token before giving up.
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      _ref.setAuthenticated(value: false);
      return;
    }

    final ok = await refresh();
    if (ok) {
      _ref.setAuthenticated(value: true);
    } else {
      // Refresh token is invalid (expired, revoked, account disabled,
      // password changed). Wipe so the next launch doesn't retry it.
      await _storage.clearAll();
      _ref.setAuthenticated(value: false);
    }
  }
}

final tokenManagerProvider = Provider<TokenManager>((ref) {
  return TokenManager(ref);
});
