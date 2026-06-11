// API client for the security/MFA endpoints.

import 'package:datasolids_mobile/core/network/dio_client.dart';
import 'package:datasolids_mobile/features/security/data/dtos/security.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecurityApi {
  SecurityApi(this._dio);
  final Dio _dio;

  Future<SecurityHome> getHome() async {
    final resp =
        await _dio.get<Map<String, dynamic>>('/auth/security/home/');
    return SecurityHome.fromJson(resp.data ?? const {});
  }

  // ----- Sessions ----------------------------------------------------------

  Future<List<LoginSessionItem>> listSessions() async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/auth/security/sessions/',
    );
    final results = (resp.data?['results'] as List<dynamic>?) ?? const [];
    return results
        .whereType<Map<String, dynamic>>()
        .map(LoginSessionItem.fromJson)
        .toList();
  }

  Future<void> revokeSession(String id) async {
    await _dio.delete<void>('/auth/security/sessions/$id/');
  }

  Future<int> revokeAllOtherSessions() async {
    final resp = await _dio.delete<Map<String, dynamic>>(
      '/auth/security/sessions/',
      queryParameters: {'all': 'true'},
    );
    return (resp.data?['revoked'] as num?)?.toInt() ?? 0;
  }

  // ----- Activity log ------------------------------------------------------

  Future<List<SecurityEventItem>> listEvents({int limit = 50}) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/auth/security/events/',
      queryParameters: {'limit': limit},
    );
    final results = (resp.data?['results'] as List<dynamic>?) ?? const [];
    return results
        .whereType<Map<String, dynamic>>()
        .map(SecurityEventItem.fromJson)
        .toList();
  }

  // ----- MFA setup + confirm + disable -------------------------------------

  Future<MfaSetupChallenge> setupTotp() async {
    final resp = await _dio.post<Map<String, dynamic>>('/auth/mfa/setup/');
    return MfaSetupChallenge.fromJson(resp.data ?? const {});
  }

  /// Returns the backup codes (only time they're shown).
  Future<List<String>> confirmTotp(String code) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/auth/mfa/confirm/',
      data: {'code': code},
    );
    final raw = (resp.data?['backup_codes'] as List<dynamic>?) ?? const [];
    return raw.map((e) => e.toString()).toList();
  }

  /// Disable MFA. Pass either [password] or [code] (TOTP). Backend accepts
  /// password as the recovery path for users who lost their authenticator;
  /// a current TOTP code is the belt-and-suspenders alternative.
  Future<void> disableMfa({String? password, String? code}) async {
    final body = <String, dynamic>{};
    if (password != null && password.isNotEmpty) {
      body['current_password'] = password;
    }
    if (code != null && code.isNotEmpty) body['code'] = code;
    await _dio.post<void>('/auth/mfa/disable/', data: body);
  }

  Future<List<String>> regenerateRecoveryCodes() async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/auth/mfa/recovery-codes/',
    );
    final raw = (resp.data?['recovery_codes'] as List<dynamic>?) ?? const [];
    return raw.map((e) => e.toString()).toList();
  }

  // ----- Login challenge ---------------------------------------------------

  /// Verify a 6-digit TOTP code (or recovery code) during login. Returns
  /// the real access + refresh token pair.
  Future<Map<String, dynamic>> verifyLoginChallenge({
    required String challengeToken,
    required String code,
  }) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/auth/mfa/challenge/',
      data: {
        'challenge_token': challengeToken,
        'code': code,
      },
    );
    return resp.data ?? const {};
  }

  // ----- Password ----------------------------------------------------------

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/auth/me/password/',
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
    return resp.data ?? const {};
  }

  // ----- Account deletion --------------------------------------------------

  /// Schedule a 30-day soft delete. Throws on 400 (wrong password) so
  /// the controller can surface a friendly error.
  Future<AccountDeletionStatus> scheduleAccountDeletion({
    required String password,
  }) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/auth/account/delete/',
      data: {'password': password},
    );
    return AccountDeletionStatus.fromJson(resp.data ?? const {});
  }

  Future<AccountDeletionStatus> getAccountDeletionStatus() async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/auth/account/delete/',
    );
    return AccountDeletionStatus.fromJson(resp.data ?? const {});
  }

  Future<void> cancelAccountDeletion() async {
    await _dio.post<void>('/auth/account/delete/cancel/');
  }
}

final securityApiProvider = Provider<SecurityApi>((ref) {
  return SecurityApi(ref.watch(dioProvider));
});
