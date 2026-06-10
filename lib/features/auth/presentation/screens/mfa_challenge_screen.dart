// MFA challenge during sign-in.
//
// Reached from LoginScreen when the API returns mfa_required + a
// short-lived challenge_token. Submits the 6-digit TOTP code (or a
// recovery code) to /auth/mfa/challenge/. On success, the access +
// refresh tokens land in TokenManager and the router redirect flips
// to /home.

import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:datasolids_mobile/features/auth/domain/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


class MfaChallengeScreen extends ConsumerStatefulWidget {
  const MfaChallengeScreen({super.key, required this.challengeToken});

  final String challengeToken;

  @override
  ConsumerState<MfaChallengeScreen> createState() =>
      _MfaChallengeScreenState();
}

class _MfaChallengeScreenState extends ConsumerState<MfaChallengeScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _isVerifying = false;
  bool _useRecoveryCode = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _controller.text.trim();
    // TOTP = 6 digits, recovery code = formatted hex like ABCDE-FGHIJ.
    if (_useRecoveryCode) {
      if (code.length < 8) {
        setState(() => _error = 'Recovery codes are 11 characters');
        return;
      }
    } else {
      if (code.length != 6) {
        setState(() => _error = 'Enter the 6-digit code from your authenticator');
        return;
      }
    }
    setState(() {
      _isVerifying = true;
      _error = null;
    });

    final result = await ref.read(authRepositoryProvider).verifyMfaChallenge(
          challengeToken: widget.challengeToken,
          code: _useRecoveryCode ? null : code,
          backupCode: _useRecoveryCode ? code : null,
        );

    if (!mounted) return;
    result.match(
      (failure) {
        setState(() {
          _isVerifying = false;
          _error = "That code didn't work — try again";
          _controller.clear();
        });
        // Re-focus the input so the user can type immediately.
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _focus.requestFocus());
      },
      (resp) {
        if (resp.access.isNotEmpty) {
          // TokenManager already saved the tokens inside verifyMfaChallenge;
          // the router redirect will route to /home automatically when it
          // sees the new authState. Pop the challenge screen so the stack
          // is clean.
          context.go('/home');
        } else {
          setState(() {
            _isVerifying = false;
            _error = "We couldn't sign you in. Please try again.";
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fieldLen = _useRecoveryCode ? 11 : 6;
    return Scaffold(
      backgroundColor: const Color(0xFF1A365D),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F2742), Color(0xFF1A365D), Color(0xFF0F2742)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkResponse(
                    onTap: () => Navigator.of(context).pop(),
                    radius: 22,
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Lock icon
                Center(
                  child: Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.14),
                      ),
                    ),
                    child: Icon(Icons.shield_outlined,
                        color: AppColors.teal500, size: 30),
                  ),
                ),
                const SizedBox(height: 22),

                Center(
                  child: Text(
                    "Confirm it's you",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _useRecoveryCode
                        ? 'Enter one of your recovery codes.'
                        : 'Enter the 6-digit code from your authenticator app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.75),
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                if (_useRecoveryCode)
                  _RecoveryCodeInput(
                    controller: _controller,
                    focusNode: _focus,
                    onChanged: (_) => setState(() {}),
                  )
                else
                  _OtpInput(
                    controller: _controller,
                    focusNode: _focus,
                    hasError: _error != null,
                    onChanged: (_) => setState(() {}),
                  ),

                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 16, color: Color(0xFFFCA5A5)),
                      const SizedBox(width: 6),
                      Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFFCA5A5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 26),

                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _isVerifying
                        || _controller.text.length < (fieldLen)
                        ? null
                        : _verify,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.teal600,
                      disabledBackgroundColor:
                          AppColors.teal600.withOpacity(0.45),
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
                            'Sign in',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 18),

                Center(
                  child: TextButton(
                    onPressed: _isVerifying
                        ? null
                        : () => setState(() {
                              _useRecoveryCode = !_useRecoveryCode;
                              _controller.clear();
                              _error = null;
                              WidgetsBinding.instance.addPostFrameCallback(
                                (_) => _focus.requestFocus(),
                              );
                            }),
                    child: Text(
                      _useRecoveryCode
                          ? 'Use your authenticator code instead'
                          : 'Use a recovery code instead',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.teal500,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────
// 6-cell OTP input — looks like the design (6 boxes, big numerals)
// ─────────────────────────────────────────────────────────────────

class _OtpInput extends StatelessWidget {
  const _OtpInput({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 6; i++) ...[
              _Cell(
                value: controller.text.length > i ? controller.text[i] : '',
                focused: controller.text.length == i,
                hasError: hasError,
              ),
              if (i < 5) const SizedBox(width: 8),
            ],
          ],
        ),
        Positioned.fill(
          child: GestureDetector(
            onTap: focusNode.requestFocus,
            child: Opacity(
              opacity: 0.0,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.number,
                showCursor: false,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: onChanged,
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
        ? const Color(0xFFFCA5A5)
        : focused
            ? AppColors.teal500
            : Colors.white.withOpacity(0.20);
    return Container(
      width: 48, height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: focused ? 2 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────
// Recovery code input — single text field, monospace, 11 chars
// (10 hex + 1 dash, e.g. ABCDE-FGHIJ)
// ─────────────────────────────────────────────────────────────────

class _RecoveryCodeInput extends StatelessWidget {
  const _RecoveryCodeInput({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autocorrect: false,
        textCapitalization: TextCapitalization.characters,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 18,
          color: Colors.white,
          letterSpacing: 2,
          fontWeight: FontWeight.w700,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f-]')),
          LengthLimitingTextInputFormatter(11),
        ],
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'ABCDE-FGHIJ',
          hintStyle: TextStyle(color: Colors.white24, letterSpacing: 2),
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
