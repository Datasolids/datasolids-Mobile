import 'package:datasolids_mobile/features/auth/data/dtos/login_request.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:datasolids_mobile/core/network/dio_client.dart';

/// Hand-written API client. Once we have ~5 features wired this way
/// we'll move to Retrofit + codegen.
class AuthApi {
  AuthApi(this._dio);
  final Dio _dio;

  Future<AuthResponse> login(LoginRequest payload) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        '/auth/login/',
        data: payload.toJson(),
      );
      return AuthResponse.fromJson(resp.data ?? const {});
    } on DioException catch (e) {
      // The mandatory-MFA-past-grace response is HTTP 403 with the same
      // JSON shape we'd parse on 200. Surface it as a normal AuthResponse
      // so the screen can route to the forced-setup flow.
      final data = e.response?.data;
      if (e.response?.statusCode == 403
          && data is Map<String, dynamic>
          && data['mfa_setup_required'] == true) {
        return AuthResponse.fromJson(data);
      }
      rethrow;
    }
  }

  /// Verify the 6-digit TOTP code (or a recovery code) during login.
  /// Returns the real access + refresh tokens. The backend accepts the
  /// recovery code under the `backup_code` field; the TOTP under `code`.
  Future<AuthResponse> verifyMfaChallenge({
    required String challengeToken,
    String? code,
    String? backupCode,
  }) async {
    assert(code != null || backupCode != null,
           'Pass either code or backupCode');
    final resp = await _dio.post<Map<String, dynamic>>(
      '/auth/mfa/challenge/',
      data: {
        'challenge_token': challengeToken,
        if (code != null && code.isNotEmpty) 'code': code,
        if (backupCode != null && backupCode.isNotEmpty)
          'backup_code': backupCode,
      },
    );
    return AuthResponse.fromJson(resp.data ?? const {});
  }

  Future<void> logout(String refresh) async {
    await _dio.post<void>('/auth/logout/', data: {'refresh': refresh});
  }

  Future<void> signupPatient({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required bool acceptTerms,
    String? phone,
  }) async {
    await _dio.post<void>('/auth/signup/patient/', data: {
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
      'accept_terms': acceptTerms,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
  }

  Future<void> requestPasswordReset(String email) async {
    await _dio.post<void>(
      '/auth/password-reset/request/',
      data: {'email': email},
    );
  }
}

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(dioProvider));
});
