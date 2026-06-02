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
  });
  final bool isSubmitting;
  final String? errorMessage;
  final bool mfaRequired;

  LoginState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    bool? mfaRequired,
  }) {
    return LoginState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      mfaRequired: mfaRequired ?? this.mfaRequired,
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
      ),
    );
  }
}

final loginControllerProvider =
    StateNotifierProvider.autoDispose<LoginController, LoginState>((ref) {
  return LoginController(ref.watch(authRepositoryProvider));
});
