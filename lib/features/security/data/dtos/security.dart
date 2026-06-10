// DTOs for the security/MFA flow.
//
// Backend endpoints:
//   GET    /auth/security/home/
//   GET    /auth/security/sessions/
//   DELETE /auth/security/sessions/?all=true
//   DELETE /auth/security/sessions/<id>/
//   GET    /auth/security/events/
//   POST   /auth/mfa/setup/                 → MfaSetupChallenge
//   POST   /auth/mfa/confirm/               → backup_codes[]
//   POST   /auth/mfa/disable/
//   POST   /auth/mfa/challenge/             → access + refresh
//   POST   /auth/mfa/recovery-codes/        → backup_codes[]
//   POST   /auth/me/password/

class SecurityHome {
  const SecurityHome({
    required this.mfaEnabled,
    required this.mfaMethod,
    required this.pastGrace,
    required this.recoveryCodesGenerated,
    required this.recoveryCodesUnusedCount,
    required this.activeSessionsCount,
    this.graceDeadline,
    this.recoveryCodesGeneratedAt,
    this.passwordChangedAt,
    this.lastEventType,
    this.lastEventAt,
  });

  final bool mfaEnabled;
  final String mfaMethod;          // 'totp' or ''
  final bool pastGrace;
  final DateTime? graceDeadline;
  final bool recoveryCodesGenerated;
  final DateTime? recoveryCodesGeneratedAt;
  final int recoveryCodesUnusedCount;
  final int activeSessionsCount;
  final DateTime? passwordChangedAt;
  final String? lastEventType;
  final DateTime? lastEventAt;

  factory SecurityHome.fromJson(Map<String, dynamic> j) {
    final mfa = (j['mfa'] as Map<String, dynamic>?) ?? const {};
    final rc = (j['recovery_codes'] as Map<String, dynamic>?) ?? const {};
    final sess = (j['sessions'] as Map<String, dynamic>?) ?? const {};
    final pw = (j['password'] as Map<String, dynamic>?) ?? const {};
    final le = (j['last_event'] as Map<String, dynamic>?) ?? const {};
    return SecurityHome(
      mfaEnabled: mfa['enabled'] as bool? ?? false,
      mfaMethod: (mfa['method'] ?? '').toString(),
      pastGrace: mfa['past_grace'] as bool? ?? false,
      graceDeadline: DateTime.tryParse(
        (mfa['grace_deadline'] ?? '').toString(),
      )?.toLocal(),
      recoveryCodesGenerated: rc['generated'] as bool? ?? false,
      recoveryCodesGeneratedAt: DateTime.tryParse(
        (rc['generated_at'] ?? '').toString(),
      )?.toLocal(),
      recoveryCodesUnusedCount: (rc['unused_count'] as num?)?.toInt() ?? 0,
      activeSessionsCount: (sess['active_count'] as num?)?.toInt() ?? 0,
      passwordChangedAt: DateTime.tryParse(
        (pw['changed_at'] ?? '').toString(),
      )?.toLocal(),
      lastEventType: le['type']?.toString(),
      lastEventAt:
          DateTime.tryParse((le['at'] ?? '').toString())?.toLocal(),
    );
  }
}

class MfaSetupChallenge {
  const MfaSetupChallenge({required this.secret, required this.provisioningUri});
  final String secret;
  final String provisioningUri;  // otpauth://totp/...

  factory MfaSetupChallenge.fromJson(Map<String, dynamic> j) =>
      MfaSetupChallenge(
        secret: (j['secret'] ?? '').toString(),
        provisioningUri: (j['provisioning_uri'] ?? '').toString(),
      );
}

class LoginSessionItem {
  const LoginSessionItem({
    required this.id,
    required this.deviceLabel,
    required this.deviceKind,
    required this.userAgent,
    required this.isCurrent,
    this.ipAddress,
    this.city,
    this.createdAt,
    this.lastActiveAt,
  });

  final String id;
  final String deviceLabel;
  final String deviceKind;
  final String userAgent;
  final String? ipAddress;
  final String? city;
  final DateTime? createdAt;
  final DateTime? lastActiveAt;
  final bool isCurrent;

  factory LoginSessionItem.fromJson(Map<String, dynamic> j) =>
      LoginSessionItem(
        id: (j['id'] ?? '').toString(),
        deviceLabel: (j['device_label'] ?? '').toString(),
        deviceKind: (j['device_kind'] ?? '').toString(),
        userAgent: (j['user_agent'] ?? '').toString(),
        ipAddress: j['ip_address']?.toString(),
        city: j['city']?.toString(),
        createdAt:
            DateTime.tryParse((j['created_at'] ?? '').toString())?.toLocal(),
        lastActiveAt: DateTime.tryParse(
          (j['last_active_at'] ?? '').toString(),
        )?.toLocal(),
        isCurrent: j['is_current'] as bool? ?? false,
      );
}

class SecurityEventItem {
  const SecurityEventItem({
    required this.id,
    required this.eventType,
    this.ipAddress,
    this.userAgent,
    this.metadata = const {},
    this.createdAt,
  });

  final String id;
  final String eventType;
  final String? ipAddress;
  final String? userAgent;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;

  factory SecurityEventItem.fromJson(Map<String, dynamic> j) =>
      SecurityEventItem(
        id: (j['id'] ?? '').toString(),
        eventType: (j['event_type'] ?? '').toString(),
        ipAddress: j['ip_address']?.toString(),
        userAgent: j['user_agent']?.toString(),
        metadata: (j['metadata'] as Map<String, dynamic>?) ?? const {},
        createdAt:
            DateTime.tryParse((j['created_at'] ?? '').toString())?.toLocal(),
      );
}

class MfaLoginResult {
  /// One of:
  ///   - 'success': access + refresh tokens issued
  ///   - 'mfa_required': MFA challenge token returned, follow with /mfa/challenge/
  ///   - 'mfa_setup_required': user past grace, must complete setup first
  const MfaLoginResult({
    required this.kind,
    this.challengeToken,
    this.accessToken,
    this.refreshToken,
    this.graceDeadline,
  });

  final String kind;
  final String? challengeToken;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? graceDeadline;

  bool get isSuccess => kind == 'success';
  bool get needsMfa => kind == 'mfa_required';
  bool get needsMfaSetup => kind == 'mfa_setup_required';
}
