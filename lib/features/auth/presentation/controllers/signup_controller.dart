import 'package:datasolids_mobile/features/auth/data/dtos/signup_request.dart';
import 'package:datasolids_mobile/features/auth/domain/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignupState {
  const SignupState({
    this.isSubmitting = false,
    this.errorMessage,
    this.succeeded = false,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final bool succeeded;

  SignupState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    bool? succeeded,
  }) {
    return SignupState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      succeeded: succeeded ?? this.succeeded,
    );
  }
}

class SignupController extends StateNotifier<SignupState> {
  SignupController(this._repo) : super(const SignupState());
  final AuthRepository _repo;

  Future<void> submit({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required bool acceptTerms,
    String? phone,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final result = await _repo.signupPatient(
      SignupRequest(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        acceptTerms: acceptTerms,
        phone: phone,
      ),
    );
    result.match(
      (failure) => state = state.copyWith(
        isSubmitting: false,
        errorMessage: failure.message,
      ),
      (_) => state = state.copyWith(
        isSubmitting: false,
        succeeded: true,
      ),
    );
  }
}

final signupControllerProvider =
    StateNotifierProvider.autoDispose<SignupController, SignupState>((ref) {
  return SignupController(ref.watch(authRepositoryProvider));
});
