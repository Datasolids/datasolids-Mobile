// Delete Account — /security/delete-account
//
// Two states:
//   1. No pending deletion → destructive confirmation form:
//        • warning card listing what we'll do (sign out other devices,
//          stop new data ingest, keep your data recoverable for 30 days)
//        • password field
//        • acknowledgement checkboxes
//        • "Schedule deletion" red CTA
//   2. Pending deletion → banner showing days remaining + Cancel CTA.
//
// Backend endpoints:
//   GET    /auth/account/delete/         status
//   POST   /auth/account/delete/         schedule (body: password)
//   POST   /auth/account/delete/cancel/  cancel

import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:datasolids_mobile/features/security/data/dtos/security.dart';
import 'package:datasolids_mobile/features/security/data/security_api.dart';
import 'package:datasolids_mobile/features/security/presentation/controllers/security_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';


class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _passwordController = TextEditingController();
  bool _ackUnderstand = false;
  bool _ackPermanent = false;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _ackUnderstand &&
      _ackPermanent &&
      _passwordController.text.isNotEmpty &&
      !_isSubmitting;

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await ref.read(securityApiProvider).scheduleAccountDeletion(
            password: _passwordController.text,
          );
      await ref.read(securityHomeControllerProvider.notifier).refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          "Account scheduled for deletion. You can cancel anytime in the next 30 days.",
        ),
      ));
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _error = 'That password is incorrect';
      });
    }
  }

  Future<void> _cancel() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(securityApiProvider).cancelAccountDeletion();
      await ref.read(securityHomeControllerProvider.notifier).refresh();
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Account deletion cancelled. Welcome back."),
      ));
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not cancel: $e'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(securityHomeControllerProvider);

    Widget body;
    if (state.home != null) {
      final home = state.home!;
      body = home.deletionPending
          ? _PendingState(
              home: home,
              onCancel: _cancel,
              isSubmitting: _isSubmitting,
            )
          : _buildConfirmForm();
    } else if (state.errorMessage != null) {
      body = const Center(
        child: Text("Couldn't load your account status"),
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
          'Delete account',
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

  Widget _buildConfirmForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero warning glyph
          Center(
            child: Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEFEC),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFA42D2D), size: 32),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Permanently delete your account',
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
            "You can change your mind anytime in the next 30 days by signing in and tapping Cancel.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 22),

          // What will happen card
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WhatRow(
                  icon: Icons.logout,
                  text: "You'll be signed out of every device.",
                ),
                SizedBox(height: 12),
                _WhatRow(
                  icon: Icons.sync_disabled,
                  text: 'No new records will be pulled from your providers.',
                ),
                SizedBox(height: 12),
                _WhatRow(
                  icon: Icons.shield_outlined,
                  text:
                      'Your data stays encrypted and recoverable for 30 days, then is permanently erased.',
                ),
                SizedBox(height: 12),
                _WhatRow(
                  icon: Icons.email_outlined,
                  text:
                      "We'll send a confirmation email so you can act quickly if this wasn't you.",
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Acknowledgements
          _CheckRow(
            value: _ackUnderstand,
            onChanged: (v) => setState(() => _ackUnderstand = v),
            label:
                'I understand my pod data, recovery codes, and active sessions will be deleted.',
          ),
          const SizedBox(height: 10),
          _CheckRow(
            value: _ackPermanent,
            onChanged: (v) => setState(() => _ackPermanent = v),
            label:
                'I understand this is permanent after the 30-day grace window.',
          ),

          const SizedBox(height: 18),

          Text(
            'Confirm with your current password',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            onChanged: (_) => setState(() {}),
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
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Row(
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

          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _canSubmit ? _submit : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFA42D2D),
                disabledBackgroundColor:
                    const Color(0xFFA42D2D).withOpacity(0.45),
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
                      'Schedule deletion',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/security');
                }
              },
              child: Text(
                'Keep my account',
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
    );
  }
}


// ─────────────────────────────────────────────────────────────────
// Pending-deletion state: countdown banner + Cancel CTA
// ─────────────────────────────────────────────────────────────────

class _PendingState extends StatelessWidget {
  const _PendingState({
    required this.home,
    required this.onCancel,
    required this.isSubmitting,
  });
  final SecurityHome home;
  final VoidCallback onCancel;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMMM d, yyyy');
    final scheduledFor = home.deletionScheduledFor;
    final days = home.deletionDaysRemaining ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
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
              child: const Icon(Icons.access_time,
                  color: Color(0xFFA15C00), size: 32),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Account scheduled for deletion',
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
            scheduledFor == null
                ? "You can cancel this anytime during the grace window."
                : "Your account will be permanently deleted on ${df.format(scheduledFor)}. You can cancel anytime before then.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 22),

          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
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
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEFEC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.hourglass_bottom,
                      color: Color(0xFFA42D2D), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$days day${days == 1 ? '' : 's'} remaining',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Until permanent deletion',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: isSubmitting ? null : onCancel,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Cancel deletion',
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
// Small reusables
// ─────────────────────────────────────────────────────────────────

class _WhatRow extends StatelessWidget {
  const _WhatRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.teal600),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.navy900,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.value,
    required this.onChanged,
    required this.label,
  });
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withOpacity(0.7)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: value ? const Color(0xFFA42D2D) : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: value
                      ? const Color(0xFFA42D2D)
                      : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: value
                  ? const Icon(Icons.check,
                      size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.navy900,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
