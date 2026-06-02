import 'package:datasolids_mobile/features/auth/domain/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForgotPasswordState {
  const ForgotPasswordState({
    this.isSubmitting = false,
    this.errorMessage,
    this.sent = false,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final bool sent;

  ForgotPasswordState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    bool? sent,
  }) {
    return ForgotPasswordState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      sent: sent ?? this.sent,
    );
  }
}

class ForgotPasswordController extends StateNotifier<ForgotPasswordState> {
  ForgotPasswordController(this._repo) : super(const ForgotPasswordState());
  final AuthRepository _repo;

  Future<void> submit(String email) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final result = await _repo.requestPasswordReset(email);
    result.match(
      (failure) => state = state.copyWith(
        isSubmitting: false,
        errorMessage: failure.message,
      ),
      // We always say "sent" even on backend errors to avoid leaking
      // which emails exist. But the backend already does this — we
      // surface only network / 5xx failures here.
      (_) => state = state.copyWith(isSubmitting: false, sent: true),
    );
  }
}

final forgotPasswordControllerProvider = StateNotifierProvider.autoDispose<
    ForgotPasswordController, ForgotPasswordState>((ref) {
  return ForgotPasswordController(ref.watch(authRepositoryProvider));
});
