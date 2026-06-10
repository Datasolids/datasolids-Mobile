import 'package:datasolids_mobile/core/errors/app_failure.dart';
import 'package:datasolids_mobile/features/auth/domain/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

/// View-model state for the login screen.
class LoginState {
  const LoginState({
    this.isSubmitting = false,
    this.errorMessage,
    this.mfaRequired = false,
    this.mfaSetupRequired = false,
    this.mfaChallengeToken,
  });
  final bool isSubmitting;
  final String? errorMessage;
  final bool mfaRequired;
  final bool mfaSetupRequired;
  final String? mfaChallengeToken;

  LoginState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    bool? mfaRequired,
    bool? mfaSetupRequired,
    String? mfaChallengeToken,
  }) {
    return LoginState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      mfaRequired: mfaRequired ?? this.mfaRequired,
      mfaSetupRequired: mfaSetupRequired ?? this.mfaSetupRequired,
      mfaChallengeToken: mfaChallengeToken ?? this.mfaChallengeToken,
    );
  }
}

class LoginController extends StateNotifier<LoginState> {
  LoginController(this._repo) : super(const LoginState());
  final AuthRepository _repo;

  Future<void> submit({required String email, required String password}) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final result = await _repo.login(email: email, password: password);
    result.match(
      (failure) => state = state.copyWith(
        isSubmitting: false,
        errorMessage: failure.message,
      ),
      (resp) => state = state.copyWith(
        isSubmitting: false,
        mfaRequired: resp.mfaRequired,
        mfaSetupRequired: resp.mfaSetupRequired,
        mfaChallengeToken: resp.mfaChallengeToken,
      ),
    );
  }
}

final loginControllerProvider =
    StateNotifierProvider.autoDispose<LoginController, LoginState>((ref) {
  return LoginController(ref.watch(authRepositoryProvider));
});
