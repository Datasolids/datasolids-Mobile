import 'package:datasolids_mobile/core/auth/token_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// "Use Face ID" / "Use Touch ID" / "Use Biometrics" — only shown when:
///   - the device exposes a biometric class, AND
///   - the user has signed in before (so we have a refresh token in
///     the keychain to validate against).
///
/// On tap we prompt the OS biometric dialog; on success we let the
/// existing TokenManager hand the user straight in without re-typing
/// credentials.
class BiometricButton extends ConsumerStatefulWidget {
  const BiometricButton({super.key});

  @override
  ConsumerState<BiometricButton> createState() => _BiometricButtonState();
}

class _BiometricButtonState extends ConsumerState<BiometricButton> {
  final _auth = LocalAuthentication();
  BiometricType? _kind;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _probe();
  }

  Future<void> _probe() async {
    try {
      final available = await _auth.canCheckBiometrics &&
          await _auth.isDeviceSupported();
      if (!available) {
        setState(() => _checking = false);
        return;
      }
      final types = await _auth.getAvailableBiometrics();
      BiometricType? choose() {
        if (types.contains(BiometricType.face)) return BiometricType.face;
        if (types.contains(BiometricType.fingerprint)) {
          return BiometricType.fingerprint;
        }
        if (types.contains(BiometricType.iris)) return BiometricType.iris;
        return types.isEmpty ? null : types.first;
      }

      setState(() {
        _kind = choose();
        _checking = false;
      });
    } catch (_) {
      setState(() => _checking = false);
    }
  }

  Future<void> _authenticate() async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Authenticate to sign in to Datasolids',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (!ok) return;
      // Warm the auth state from secure storage. If a valid refresh
      // token exists, the router redirects to /home automatically.
      await ref.read(tokenManagerProvider).warmFromStorage();
    } catch (_) {
      // Silently swallow — the user can still type their password.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking || _kind == null) return const SizedBox.shrink();

    final label = switch (_kind!) {
      BiometricType.face => 'Use Face ID',
      BiometricType.fingerprint => 'Use Touch ID',
      BiometricType.iris => 'Use Iris',
      _ => 'Use Biometrics',
    };
    final icon = switch (_kind!) {
      BiometricType.face => Icons.face_outlined,
      BiometricType.fingerprint => Icons.fingerprint,
      _ => Icons.lock_outline,
    };

    return Column(
      children: [
        InkWell(
          onTap: _authenticate,
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 1,
              ),
            ),
            child: Icon(icon, size: 28, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
