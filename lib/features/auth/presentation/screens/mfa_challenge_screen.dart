// MFA challenge during sign-in. Matches "Auth: MFA Challenge" design —
// cream background, small teal shield icon, 6-cell OTP, "Use a recovery
// code instead" toggle, amber "Having trouble?" info card, Continue CTA.

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

  int get _expectedLength => _useRecoveryCode ? 11 : 6;

  Future<void> _verify() async {
    final code = _controller.text.trim();
    if (!_useRecoveryCode && code.length != 6) {
      setState(() => _error = "Enter the 6-digit code from your authenticator");
      return;
    }
    if (_useRecoveryCode && code.length < 8) {
      setState(() => _error = "Recovery codes are 11 characters");
      return;
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
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _focus.requestFocus());
      },
      (resp) {
        if (resp.access.isNotEmpty) {
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
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Back button (white rounded square)
              Align(
                alignment: Alignment.centerLeft,
                child: InkResponse(
                  onTap: () => Navigator.of(context).pop(),
                  radius: 26,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.border.withOpacity(0.6),
                      ),
                    ),
                    child: Icon(Icons.arrow_back,
                        color: AppColors.navy900, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Teal shield icon
              Center(
                child: Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.teal600,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.shield_outlined,
                      color: Colors.white, size: 32),
                ),
              ),
              const SizedBox(height: 22),

              Text(
                "Confirm it's you",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _useRecoveryCode
                    ? 'Enter one of your recovery codes.'
                    : 'Enter the 6-digit code from your authenticator app to sign in to your pod.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 30),

              if (_useRecoveryCode)
                _RecoveryCodeInput(
                  controller: _controller,
                  focusNode: _focus,
                  onChanged: (_) => setState(() {}),
                )
              else
                _OtpRow(
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

              // Recovery-code toggle link
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
                        ? 'Use your authenticator code instead →'
                        : 'Use a recovery code instead →',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.teal600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Amber "Having trouble?" info card
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 18, color: Color(0xFFA15C00)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFA15C00),
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            const TextSpan(
                              text: "Having trouble? If you've lost your device and recovery codes, please ",
                            ),
                            TextSpan(
                              text: "contact support",
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const TextSpan(text: " to verify your identity."),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _isVerifying
                      || _controller.text.length < _expectedLength
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
                          'Continue',
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


// ─────────────────────────────────────────────────────────────────
// 6-cell OTP row — matches the design.
// Filled cells get a 2px teal border; empty cells get a 1px gray border.
// ─────────────────────────────────────────────────────────────────

class _OtpRow extends StatelessWidget {
  const _OtpRow({
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
                filled: controller.text.length > i,
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
    required this.filled,
    required this.focused,
    required this.hasError,
  });
  final String value;
  final bool filled;
  final bool focused;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final teal = hasError ? const Color(0xFFE0524F) : AppColors.teal600;
    final gray = AppColors.border;

    return Container(
      width: 48, height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (filled || focused) ? teal : gray,
          width: (filled || focused) ? 2 : 1,
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


// ─────────────────────────────────────────────────────────────────
// Recovery code input — single text field with monospaced font.
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
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autocorrect: false,
      textCapitalization: TextCapitalization.characters,
      cursorColor: AppColors.teal600,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 17,
        color: AppColors.navy900,
        letterSpacing: 2,
        fontWeight: FontWeight.w700,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f-]')),
        LengthLimitingTextInputFormatter(11),
      ],
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: 'ABCDE-FGHIJ',
        hintStyle: TextStyle(
          color: AppColors.textSubtle.withOpacity(0.6),
          letterSpacing: 2,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w700,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border.withOpacity(0.6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border.withOpacity(0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.teal600, width: 1.5),
        ),
      ),
      onChanged: onChanged,
    );
  }
}
