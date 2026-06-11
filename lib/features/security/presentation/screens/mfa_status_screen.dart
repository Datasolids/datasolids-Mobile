// MFA Status screen — /security/mfa-status
//
// Shows the user's current MFA setup at a glance:
//   • Method card (Authenticator app · Enabled <date>) with green status pill
//   • Recovery codes card (unused count + Regenerate / View)
//   • Switch method (TOTP-only for now; surfaces SMS / passkey when ready)
//   • Destructive "Turn off two-factor" footer that opens a confirm sheet
//     accepting either the current password or a fresh TOTP code.
//
// Backend: GET /security/home/, POST /mfa/recovery-codes/, POST /mfa/disable/

import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:datasolids_mobile/features/security/data/dtos/security.dart';
import 'package:datasolids_mobile/features/security/data/security_api.dart';
import 'package:datasolids_mobile/features/security/presentation/controllers/security_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';


class MfaStatusScreen extends ConsumerWidget {
  const MfaStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(securityHomeControllerProvider);

    Widget body;
    if (state.home != null) {
      body = _Body(home: state.home!);
    } else if (state.errorMessage != null) {
      body = _ErrorBlock(
        onRetry: () => ref
            .read(securityHomeControllerProvider.notifier)
            .refresh(),
      );
    } else {
      body = const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.navy900,
        leading: const BackButton(),
        title: Text(
          'Two-factor authentication',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.navy900,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SafeArea(top: false, child: body),
    );
  }
}


class _Body extends ConsumerWidget {
  const _Body({required this.home});
  final SecurityHome home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!home.mfaEnabled) return _NotEnabledBlock(home: home);

    final df = DateFormat('MMMM d, yyyy');
    final since = home.recoveryCodesGeneratedAt;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ───── Method card ────────────────────────────────────────────
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IconBox(
                      icon: Icons.lock_outline,
                      color: AppColors.teal600,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Authenticator app',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            since == null
                                ? 'Enabled'
                                : 'Enabled · ${df.format(since)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const _EnabledPill(),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: AppColors.border.withOpacity(0.5)),
                const SizedBox(height: 12),
                // Switch method
                InkWell(
                  onTap: () => context.push('/security/mfa-choose'),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(Icons.swap_horiz,
                            size: 18, color: AppColors.navy900),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Switch method',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy900,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            size: 18, color: AppColors.textSubtle),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ───── Recovery codes card ────────────────────────────────────
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IconBox(
                      icon: Icons.vpn_key_outlined,
                      color: const Color(0xFFA15C00),
                      background: const Color(0xFFFFF4DA),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recovery codes',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            home.recoveryCodesGenerated
                                ? '${home.recoveryCodesUnusedCount} of 10 unused'
                                : 'Not generated yet',
                            style: TextStyle(
                              fontSize: 12,
                              color: home.recoveryCodesUnusedCount <= 2
                                  ? const Color(0xFFA42D2D)
                                  : AppColors.textMuted,
                              fontWeight: home.recoveryCodesUnusedCount <= 2
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (home.recoveryCodesUnusedCount <= 2 &&
                    home.recoveryCodesGenerated)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding:
                        const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEFEC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 16, color: Color(0xFFA42D2D)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "You're running low on recovery codes. Generate a fresh set to stay covered if you lose your authenticator.",
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFFA42D2D),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.push('/security/recovery-codes'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.navy900,
                          side: BorderSide(
                            color: AppColors.border.withOpacity(0.8),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'View codes',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _regenerate(context, ref),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.teal600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Regenerate',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ───── Turn off two-factor ─────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () => _confirmDisable(context, ref),
            icon: const Icon(Icons.power_settings_new, size: 18),
            label: const Text(
              'Turn off two-factor',
              style:
                  TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFA42D2D),
              side: const BorderSide(color: Color(0xFFE0524F)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Turning off two-factor will reduce your account security. We'll keep your data safe but recommend leaving it on.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _regenerate(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Generate new recovery codes?'),
        content: const Text(
          'Your existing recovery codes will stop working immediately. You can copy, download, or print the new ones on the next screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Generate'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      final codes =
          await ref.read(securityApiProvider).regenerateRecoveryCodes();
      await ref.read(securityHomeControllerProvider.notifier).refresh();
      if (!context.mounted) return;
      context.push('/security/recovery-codes-after-setup', extra: codes);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not regenerate codes: $e'),
        ));
      }
    }
  }

  Future<void> _confirmDisable(BuildContext context, WidgetRef ref) async {
    final disabled = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DisableSheet(),
    );
    if (disabled == true && context.mounted) {
      await ref.read(securityHomeControllerProvider.notifier).refresh();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Two-factor authentication is off.'),
      ));
      // Safe pop: if this screen is the only thing on the stack
      // (e.g. deep-linked here), fall back to /security instead of
      // popping into the void.
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/security');
      }
    }
  }
}


// ─────────────────────────────────────────────────────────────────
// "Not enabled" empty state — when the user lands here but mfa.enabled
// is false. Sends them straight into the setup flow.
// ─────────────────────────────────────────────────────────────────

class _NotEnabledBlock extends StatelessWidget {
  const _NotEnabledBlock({required this.home});
  final SecurityHome home;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4DA),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.shield_outlined,
                  color: Color(0xFFA15C00), size: 32),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Two-factor is off',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.navy900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Adding a second step at sign-in keeps your pod safe even if your password is leaked.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: () => context.push('/security/mfa-choose'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Turn on two-factor',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────
// Disable confirmation bottom sheet — password OR TOTP code.
// Returns true on success.
// ─────────────────────────────────────────────────────────────────

class _DisableSheet extends ConsumerStatefulWidget {
  const _DisableSheet();

  @override
  ConsumerState<_DisableSheet> createState() => _DisableSheetState();
}

class _DisableSheetState extends ConsumerState<_DisableSheet> {
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  bool _useCode = false;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_useCode && _codeController.text.trim().length != 6) {
      setState(() => _error = 'Enter the 6-digit code from your app');
      return;
    }
    if (!_useCode && _passwordController.text.isEmpty) {
      setState(() => _error = 'Enter your current password');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await ref.read(securityApiProvider).disableMfa(
        password: _useCode ? null : _passwordController.text,
        code: _useCode ? _codeController.text.trim() : null,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _error = _useCode
            ? "That code didn't work — try again"
            : 'That password is incorrect';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFAF7F2),
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEFEC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFA42D2D), size: 28),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Turn off two-factor?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.navy900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _useCode
                  ? 'Enter a fresh 6-digit code from your authenticator to confirm.'
                  : "Enter your current password to confirm. We'll keep your recovery codes for 30 days in case you change your mind.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            if (_useCode)
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                  color: AppColors.navy900,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  hintText: '••••••',
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        BorderSide(color: AppColors.border.withOpacity(0.6)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        BorderSide(color: AppColors.border.withOpacity(0.6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: AppColors.teal600, width: 1.5),
                  ),
                ),
              )
            else
              TextField(
                controller: _passwordController,
                autofocus: true,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Current password',
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.textSubtle,
                    ),
                    onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: AppColors.border.withOpacity(0.6)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: AppColors.border.withOpacity(0.6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: AppColors.teal600, width: 1.5),
                  ),
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 14, color: Color(0xFFA42D2D)),
                  const SizedBox(width: 6),
                  Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFFA42D2D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => setState(() {
                          _useCode = !_useCode;
                          _error = null;
                        }),
                child: Text(
                  _useCode
                      ? 'Use my password instead'
                      : 'Use an authenticator code instead',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teal600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFA42D2D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Turn off two-factor',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────
// Reusable bits
// ─────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.color, this.background});
  final IconData icon;
  final Color color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: background ?? color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _EnabledPill extends StatelessWidget {
  const _EnabledPill();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFDFF5E5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.check_circle, size: 12, color: Color(0xFF1F8F4D)),
          SizedBox(width: 4),
          Text(
            'ENABLED',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: Color(0xFF1F8F4D),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined,
              color: AppColors.textMuted, size: 32),
          const SizedBox(height: 10),
          Text("Couldn't load your settings",
              style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: AppColors.navy900,
              )),
          TextButton(
            onPressed: onRetry,
            child: Text('Retry',
                style: TextStyle(
                  color: AppColors.teal600,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ),
    );
  }
}
