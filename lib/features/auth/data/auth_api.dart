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
    final resp = await _dio.post<Map<String, dynamic>>(
      '/auth/login/',
      data: payload.toJson(),
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
