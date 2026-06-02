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
    this.mfaChallengeToken,
  });

  final String access;
  final String refresh;
  final bool mfaRequired;
  final String? mfaChallengeToken;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      access: (json['access'] as String?) ?? '',
      refresh: (json['refresh'] as String?) ?? '',
      mfaRequired: (json['mfa_required'] as bool?) ?? false,
      mfaChallengeToken: json['mfa_challenge_token'] as String?,
    );
  }
}
