// MFA setup flow — three screens:
//   1. MfaMethodChoiceScreen     /security/mfa-choose
//   2. MfaTotpQrScreen           /security/mfa-totp-qr
//   3. MfaTotpVerifyScreen       /security/mfa-totp-verify?secret=...&uri=...
//   4. MfaRecoveryCodesScreen    /security/recovery-codes  (also reachable
//                                from Security home as a standalone view)
//
// Backend endpoints used:
//   POST /auth/mfa/setup/    → returns secret + provisioning_uri
//   POST /auth/mfa/confirm/  → returns backup codes (one shot)
//   POST /auth/mfa/recovery-codes/ → regenerate codes

import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:datasolids_mobile/features/security/data/security_api.dart';
import 'package:datasolids_mobile/features/security/presentation/controllers/security_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';


// ============================================================================
// 1. Method choice screen
// ============================================================================

class MfaMethodChoiceScreen extends StatelessWidget {
  const MfaMethodChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.navy900,
        leading: const BackButton(),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero shield icon
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
              Center(
                child: Text(
                  'Add a second step at sign-in',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy900,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Multi-factor authentication adds an extra layer of security to your pod, ensuring only you can access your health data.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _MethodCard(
                icon: Icons.lock_outline,
                title: 'Authenticator app',
                body: 'Free, works offline, and takes under a minute to set up.',
                badge: 'RECOMMENDED',
                badgeColor: AppColors.teal600,
                onTap: () => context.push('/security/mfa-totp-qr'),
              ),
              const SizedBox(height: 12),
              _MethodCard(
                icon: Icons.fingerprint,
                title: 'Passkey',
                body: 'Sign in with Face ID or fingerprint. No separate app needed.',
                badge: 'COMING SOON',
                badgeColor: AppColors.textMuted,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Passkey support is coming soon.'),
                  ));
                },
              ),
              const SizedBox(height: 12),
              _MethodCard(
                icon: Icons.chat_bubble_outline,
                title: 'Text message',
                body: 'Standard SMS verification. Carrier rates may apply.',
                badge: 'LESS SECURE',
                badgeColor: const Color(0xFFA15C00),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('SMS MFA is coming soon.'),
                  ));
                },
              ),
              const SizedBox(height: 26),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Skip for now',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.badge,
    required this.badgeColor,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String body;
  final String badge;
  final Color badgeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.teal600.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.teal600, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================================
// 2. QR setup screen
// ============================================================================

class MfaTotpQrScreen extends ConsumerStatefulWidget {
  const MfaTotpQrScreen({super.key});
  @override
  ConsumerState<MfaTotpQrScreen> createState() => _MfaTotpQrScreenState();
}

class _MfaTotpQrScreenState extends ConsumerState<MfaTotpQrScreen> {
  bool _isLoading = true;
  bool _showSecret = false;
  String? _error;
  String _secret = '';
  String _uri = '';

  @override
  void initState() {
    super.initState();
    _fetchChallenge();
  }

  Future<void> _fetchChallenge() async {
    try {
      final ch = await ref.read(securityApiProvider).setupTotp();
      setState(() {
        _secret = ch.secret;
        _uri = ch.provisioningUri;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.navy900,
        leading: const BackButton(),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Scan with your authenticator',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Open Google Authenticator, Authy, or 1Password and scan this QR code to link your account.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // QR card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          height: 240, width: 240,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _error != null
                          ? Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Icon(Icons.cloud_off_outlined,
                                      size: 32, color: AppColors.textMuted),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Couldn't load the QR code",
                                    style: TextStyle(color: AppColors.navy900),
                                  ),
                                  TextButton(
                                    onPressed: _fetchChallenge,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : QrImageView(
                              data: _uri,
                              version: QrVersions.auto,
                              size: 240,
                              backgroundColor: Colors.white,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Color(0xFF1A365D),
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Color(0xFF1A365D),
                              ),
                            ),
                ),
              ),

              const SizedBox(height: 14),
              // Can't scan disclosure
              InkWell(
                onTap: () => setState(() => _showSecret = !_showSecret),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Can't scan?",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy900,
                          ),
                        ),
                      ),
                      Icon(
                        _showSecret
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppColors.textSubtle,
                      ),
                    ],
                  ),
                ),
              ),
              if (_showSecret) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF1F4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter this secret manually in your authenticator:',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              _secret,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_outlined, size: 18),
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: _secret),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Secret copied'),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _isLoading || _error != null
                      ? null
                      : () => context.push('/security/mfa-totp-verify'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.teal600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Next',
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
        ),
      ),
    );
  }
}


// ============================================================================
// 3. Verify code screen
// ============================================================================

class MfaTotpVerifyScreen extends ConsumerStatefulWidget {
  const MfaTotpVerifyScreen({super.key});
  @override
  ConsumerState<MfaTotpVerifyScreen> createState() =>
      _MfaTotpVerifyScreenState();
}

class _MfaTotpVerifyScreenState extends ConsumerState<MfaTotpVerifyScreen> {
  final _controller = TextEditingController();
  bool _isVerifying = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _controller.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    setState(() {
      _isVerifying = true;
      _error = null;
    });
    try {
      final codes = await ref.read(securityApiProvider).confirmTotp(code);
      // Refresh home so the screen reflects the new MFA state.
      await ref.read(securityHomeControllerProvider.notifier).refresh();
      if (!mounted) return;
      // Show recovery codes once.
      context.go('/security/recovery-codes-after-setup',
                 extra: codes);
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _error = "That code didn't work — try again";
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.navy900,
        leading: const BackButton(),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter the 6-digit code',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Type the verification code from your authenticator app to confirm setup.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 30),

              // 6-cell input
              _OtpInput(controller: _controller, hasError: _error != null),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 16, color: Color(0xFFA42D2D)),
                    const SizedBox(width: 6),
                    Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFA42D2D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 22),
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    final t = (data?.text ?? '').trim();
                    if (t.length >= 6 && RegExp(r'^\d{6}$').hasMatch(t)) {
                      _controller.text = t.substring(0, 6);
                      setState(() {});
                    }
                  },
                  icon: Icon(Icons.content_paste,
                      size: 16, color: AppColors.teal600),
                  label: Text(
                    'Paste from clipboard',
                    style: TextStyle(
                      color: AppColors.teal600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _isVerifying ? null : _verify,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.teal600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Verify',
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
        ),
      ),
    );
  }
}


/// 6-cell OTP input (one underline-style box per digit). Backed by a
/// single TextField for IME / paste / autofill compatibility.
class _OtpInput extends StatefulWidget {
  const _OtpInput({required this.controller, required this.hasError});
  final TextEditingController controller;
  final bool hasError;

  @override
  State<_OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<_OtpInput> {
  late final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Visible cells.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 6; i++) ...[
              _Cell(
                value: widget.controller.text.length > i
                    ? widget.controller.text[i]
                    : '',
                focused: widget.controller.text.length == i,
                hasError: widget.hasError,
              ),
              if (i < 5) const SizedBox(width: 8),
            ],
          ],
        ),
        // Invisible TextField on top capturing input.
        Positioned.fill(
          child: GestureDetector(
            onTap: () => _focus.requestFocus(),
            child: Opacity(
              opacity: 0.0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                keyboardType: TextInputType.number,
                maxLength: 6,
                showCursor: false,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: (_) => (context as Element).markNeedsBuild(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.value,
    required this.focused,
    required this.hasError,
  });
  final String value;
  final bool focused;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? const Color(0xFFE0524F)
        : focused
            ? AppColors.teal600
            : AppColors.border;
    return Container(
      width: 48, height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: focused ? 2 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        value,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: AppColors.navy900,
        ),
      ),
    );
  }
}


// ============================================================================
// 4. Recovery codes screen
//    - Shown right after MFA setup with the codes (passed via go_router extra)
//    - Standalone view: regenerates new codes when visited directly
// ============================================================================

class RecoveryCodesScreen extends ConsumerStatefulWidget {
  const RecoveryCodesScreen({super.key, this.initialCodes});

  /// If provided, those codes are shown (this is the post-setup display).
  /// If null, the screen offers a "Generate new codes" CTA that calls
  /// the regenerate endpoint.
  final List<String>? initialCodes;

  @override
  ConsumerState<RecoveryCodesScreen> createState() =>
      _RecoveryCodesScreenState();
}

class _RecoveryCodesScreenState extends ConsumerState<RecoveryCodesScreen> {
  List<String>? _codes;
  bool _acknowledged = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _codes = widget.initialCodes;
  }

  Future<void> _generate() async {
    setState(() => _isGenerating = true);
    try {
      final codes =
          await ref.read(securityApiProvider).regenerateRecoveryCodes();
      setState(() {
        _codes = codes;
        _isGenerating = false;
        _acknowledged = false;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not generate codes: $e'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.navy900,
        leading: const BackButton(),
        title: Text(
          'Recovery codes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.navy900,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _codes == null
                    ? 'Generate recovery codes'
                    : 'Save your recovery codes',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _codes == null
                    ? 'If you lose your authenticator, recovery codes let you sign in.'
                    : "Store these somewhere safe. They're shown only once and let you sign in if you lose your authenticator.",
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              if (_codes != null) ...[
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                  child: Column(
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in _codes!)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF1F4),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                c,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await Clipboard.setData(ClipboardData(
                                  text: _codes!.join('\n'),
                                ));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Codes copied'),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.copy_outlined, size: 16),
                              label: const Text('Copy all'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Checkbox(
                      value: _acknowledged,
                      onChanged: (v) =>
                          setState(() => _acknowledged = v ?? false),
                      activeColor: AppColors.teal600,
                    ),
                    Expanded(
                      child: Text(
                        "I've saved my recovery codes somewhere safe.",
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.navy900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _acknowledged
                        ? () => context.go('/security')
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.teal600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _isGenerating ? null : _generate,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.teal600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isGenerating
                        ? const SizedBox(
                            height: 18, width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Generate new codes',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
