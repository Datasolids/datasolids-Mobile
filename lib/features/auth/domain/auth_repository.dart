import 'package:datasolids_mobile/core/auth/token_manager.dart';
import 'package:datasolids_mobile/core/errors/app_failure.dart';
import 'package:datasolids_mobile/features/auth/data/auth_api.dart';
import 'package:datasolids_mobile/features/auth/data/dtos/login_request.dart';
import 'package:datasolids_mobile/features/auth/data/dtos/signup_request.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

/// Domain repository for everything auth-related the UI talks to.
/// Returns `Either<AppFailure, T>` so screens stay free of try/catch
/// gymnastics.
class AuthRepository {
  AuthRepository(this._api, this._tokens);

  final AuthApi _api;
  final TokenManager _tokens;

  Future<Either<AppFailure, AuthResponse>> login({
    required String email,
    required String password,
  }) async {
    try {
      final resp = await _api.login(LoginRequest(
        email: email.trim().toLowerCase(),
        password: password,
      ));
      if (!resp.mfaRequired && resp.access.isNotEmpty) {
        await _tokens.saveTokens(access: resp.access, refresh: resp.refresh);
      }
      return Right(resp);
    } on DioException catch (e) {
      final failure = e.error is AppFailure
          ? e.error! as AppFailure
          : AppFailure.fromDio(e);
      return Left(failure);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  /// Verify the 6-digit MFA code (or recovery code) during login.
  /// On success this saves the access + refresh tokens so the user is
  /// considered logged in immediately afterwards.
  Future<Either<AppFailure, AuthResponse>> verifyMfaChallenge({
    required String challengeToken,
    String? code,
    String? backupCode,
  }) async {
    try {
      final resp = await _api.verifyMfaChallenge(
        challengeToken: challengeToken,
        code: code,
        backupCode: backupCode,
      );
      if (resp.access.isNotEmpty) {
        await _tokens.saveTokens(access: resp.access, refresh: resp.refresh);
      }
      return Right(resp);
    } on DioException catch (e) {
      final failure = e.error is AppFailure
          ? e.error! as AppFailure
          : AppFailure.fromDio(e);
      return Left(failure);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  Future<Either<AppFailure, Unit>> signOut() async {
    await _tokens.signOut();
    return const Right(unit);
  }

  Future<Either<AppFailure, Unit>> signupPatient(SignupRequest req) async {
    try {
      await _api.signupPatient(
        email: req.email.trim().toLowerCase(),
        password: req.password,
        firstName: req.firstName.trim(),
        lastName: req.lastName.trim(),
        acceptTerms: req.acceptTerms,
        phone: req.phone?.trim(),
      );
      return const Right(unit);
    } on DioException catch (e) {
      final failure =
          e.error is AppFailure ? e.error! as AppFailure : AppFailure.fromDio(e);
      return Left(failure);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  Future<Either<AppFailure, Unit>> requestPasswordReset(String email) async {
    try {
      await _api.requestPasswordReset(email.trim().toLowerCase());
      return const Right(unit);
    } on DioException catch (e) {
      final failure =
          e.error is AppFailure ? e.error! as AppFailure : AppFailure.fromDio(e);
      return Left(failure);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(authApiProvider),
    ref.watch(tokenManagerProvider),
  );
});
