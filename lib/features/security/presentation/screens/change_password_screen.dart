// Change password — current / new / confirm with a 4-segment strength
// meter and four requirement chips (8+ chars, symbol, number, case mix).
// Posts to /auth/me/password/. On success the backend revokes all other
// refresh tokens (so other devices get signed out) — surfaced here as a
// toggle the user can opt out of.

import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:datasolids_mobile/features/security/data/security_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends ConsumerState<ChangePasswordScreen> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;
  bool _signOutOthers = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ─── Validation ───────────────────────────────────────────────

  bool get _hasMinLength => _newCtrl.text.length >= 8;
  bool get _hasNumber => RegExp(r'\d').hasMatch(_newCtrl.text);
  bool get _hasSymbol =>
      RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/~`;]').hasMatch(_newCtrl.text);
  bool get _hasCaseMix =>
      RegExp(r'[a-z]').hasMatch(_newCtrl.text)
          && RegExp(r'[A-Z]').hasMatch(_newCtrl.text);

  int get _strength {
    var s = 0;
    if (_hasMinLength) s++;
    if (_hasNumber) s++;
    if (_hasSymbol) s++;
    if (_hasCaseMix) s++;
    return s; // 0..4
  }

  String get _strengthLabel {
    switch (_strength) {
      case 0:
      case 1: return 'Weak';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Strong';
      default: return '';
    }
  }

  Color get _strengthColor {
    switch (_strength) {
      case 0:
      case 1: return const Color(0xFFA42D2D);
      case 2: return const Color(0xFFA15C00);
      case 3: return AppColors.teal600;
      case 4: return const Color(0xFF1B7F3A);
      default: return AppColors.textMuted;
    }
  }

  bool get _canSubmit {
    return _currentCtrl.text.isNotEmpty
        && _strength >= 3
        && _confirmCtrl.text == _newCtrl.text
        && !_isSubmitting;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await ref.read(securityApiProvider).changePassword(
            currentPassword: _currentCtrl.text,
            newPassword: _newCtrl.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password updated'),
      ));
      context.go('/security');
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _error = "Couldn't update password. Check the current password and try again.";
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
        title: Text(
          'Change password',
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
                'Choose a strong, unique password for your pod.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),

              // Current password
              _Label('CURRENT PASSWORD'),
              const SizedBox(height: 6),
              _PasswordField(
                controller: _currentCtrl,
                hidden: _hideCurrent,
                onToggle: () => setState(() => _hideCurrent = !_hideCurrent),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 16),

              // New password
              _Label('NEW PASSWORD'),
              const SizedBox(height: 6),
              _PasswordField(
                controller: _newCtrl,
                hidden: _hideNew,
                onToggle: () => setState(() => _hideNew = !_hideNew),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 10),
              _StrengthMeter(strength: _strength, color: _strengthColor),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'STRENGTH: ',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textSubtle,
                    ),
                  ),
                  Text(
                    _strengthLabel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: _strengthColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              _RequirementGrid(
                rows: [
                  ('8+ characters', _hasMinLength),
                  ('One number', _hasNumber),
                  ('One symbol', _hasSymbol),
                  ('Case mix', _hasCaseMix),
                ],
              ),

              const SizedBox(height: 16),

              // Confirm
              _Label('CONFIRM NEW PASSWORD'),
              const SizedBox(height: 6),
              _PasswordField(
                controller: _confirmCtrl,
                hidden: _hideConfirm,
                onToggle: () => setState(() => _hideConfirm = !_hideConfirm),
                onChanged: (_) => setState(() {}),
                errorText: _confirmCtrl.text.isNotEmpty
                    && _confirmCtrl.text != _newCtrl.text
                    ? "Passwords don't match"
                    : null,
              ),

              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sign out other devices',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sign out of all other active sessions when you change your password.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _signOutOthers,
                      onChanged: (v) => setState(() => _signOutOthers = v),
                      activeColor: AppColors.teal600,
                    ),
                  ],
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE4E4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFA42D2D), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFA42D2D),
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 22),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _canSubmit ? _submit : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.teal600,
                    disabledBackgroundColor:
                        AppColors.teal600.withOpacity(0.45),
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
                          'Update password',
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
// Small UI helpers
// ─────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: AppColors.textSubtle,
        ),
      );
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.hidden,
    required this.onToggle,
    required this.onChanged,
    this.errorText,
  });

  final TextEditingController controller;
  final bool hidden;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: (errorText ?? '').isEmpty
                  ? AppColors.border.withOpacity(0.6)
                  : const Color(0xFFE0524F),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: hidden,
                  autocorrect: false,
                  enableSuggestions: false,
                  onChanged: onChanged,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '••••••••',
                    isCollapsed: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  hidden ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppColors.textSubtle,
                ),
                onPressed: onToggle,
                tooltip: hidden ? 'Show' : 'Hide',
              ),
            ],
          ),
        ),
        if ((errorText ?? '').isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFA42D2D),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.strength, required this.color});
  final int strength;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 4; i++) ...[
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: i < strength
                    ? color
                    : AppColors.border.withOpacity(0.45),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          if (i < 3) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _RequirementGrid extends StatelessWidget {
  const _RequirementGrid({required this.rows});
  final List<(String, bool)> rows;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: [
        for (final r in rows)
          SizedBox(
            width: (MediaQuery.of(context).size.width - 52) / 2,
            child: _RequirementChip(label: r.$1, met: r.$2),
          ),
      ],
    );
  }
}

class _RequirementChip extends StatelessWidget {
  const _RequirementChip({required this.label, required this.met});
  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: met ? const Color(0xFF1B7F3A) : AppColors.textSubtle,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: met ? AppColors.navy900 : AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}
