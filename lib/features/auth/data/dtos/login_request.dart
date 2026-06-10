// Plain DTOs. We keep these dumb — domain entities live in
// `features/auth/domain/` and translate to/from these classes.

class LoginRequest {
  const LoginRequest({required this.email, required this.password});
  final String email;
  final String password;

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class AuthResponse {
  const AuthResponse({
    required this.access,
    required this.refresh,
    this.mfaRequired = false,
    this.mfaSetupRequired = false,
    this.mfaChallengeToken,
    this.graceDeadline,
  });

  /// Access token (empty when mfaRequired or mfaSetupRequired).
  final String access;
  /// Refresh token (empty when mfaRequired or mfaSetupRequired).
  final String refresh;
  /// User has MFA enabled. Client must POST /auth/mfa/challenge/ with the
  /// 6-digit code (or a recovery code) to receive real access tokens.
  final bool mfaRequired;
  /// User is past the soft MFA grace deadline. They must complete MFA
  /// setup before any access tokens will be issued. The challenge token
  /// scopes the next request to /auth/mfa/setup/ only.
  final bool mfaSetupRequired;
  /// Shared by both mfaRequired and mfaSetupRequired flows.
  final String? mfaChallengeToken;
  /// Only set when mfaSetupRequired — tells the UI when grace expired.
  final DateTime? graceDeadline;

  bool get isAuthenticated =>
      !mfaRequired && !mfaSetupRequired && access.isNotEmpty;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      access: (json['access'] as String?) ?? '',
      refresh: (json['refresh'] as String?) ?? '',
      mfaRequired: (json['mfa_required'] as bool?) ?? false,
      mfaSetupRequired: (json['mfa_setup_required'] as bool?) ?? false,
      // Backend uses `challenge_token` (not `mfa_challenge_token`) on the
      // setup-required path; accept either field name for safety.
      mfaChallengeToken: (json['challenge_token'] as String?)
          ?? (json['mfa_challenge_token'] as String?),
      graceDeadline:
          DateTime.tryParse((json['grace_deadline'] ?? '').toString())
              ?.toLocal(),
    );
  }
}
