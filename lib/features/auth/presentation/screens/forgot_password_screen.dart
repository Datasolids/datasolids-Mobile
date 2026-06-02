// Forgot-password screen — matches the auth visual language exactly:
// navy-to-teal gradient, brand logo, white card. Backend endpoint:
//   POST /api/v1/auth/password-reset/request/ { "email": "..." }
// Always returns 200 server-side (we never confirm whether the email
// exists, to avoid enumeration). UI shows a generic success state.

import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:datasolids_mobile/core/widgets/auth_gradient_background.dart';
import 'package:datasolids_mobile/core/widgets/auth_input_field.dart';
import 'package:datasolids_mobile/core/widgets/brand_logo.dart';
import 'package:datasolids_mobile/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:datasolids_mobile/features/auth/presentation/widgets/auth_footer_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(forgotPasswordControllerProvider.notifier)
        .submit(_emailCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);
    return Scaffold(
      body: AuthGradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                // Back button + brand mark.
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/login'),
                  ),
                ),
                const SizedBox(height: 8),
                const BrandLogo(size: 56),
                const SizedBox(height: 16),
                const Text(
                  'Reset your password',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  state.sent
                      ? "If we have an account for that email, we just sent\nyou a reset link."
                      : "We'll email you a secure link to set a new\npassword.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.92),
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),

                // Card.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: state.sent
                      ? _SuccessBlock(
                          onBack: () => context.go('/login'),
                        )
                      : Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AuthInputField(
                                label: 'Email address',
                                controller: _emailCtrl,
                                icon: Icons.mail_outline,
                                hintText: 'name@example.com',
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                validator: _validateEmail,
                              ),
                              if (state.errorMessage != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.red700.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.red700
                                          .withOpacity(0.25),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: AppColors.red700,
                                          size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          state.errorMessage!,
                                          style: const TextStyle(
                                            color: AppColors.red700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 52,
                                child: FilledButton(
                                  onPressed:
                                      state.isSubmitting ? null : _submit,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.navy900,
                                    disabledBackgroundColor: AppColors
                                        .navy900
                                        .withOpacity(0.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: state.isSubmitting
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Text(
                                          'Send reset link',
                                          style: TextStyle(
                                            fontSize: 16,
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

                const SizedBox(height: 24),
                const AuthFooterLinks(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Required.';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok ? null : 'Enter a valid email address.';
  }
}

class _SuccessBlock extends StatelessWidget {
  const _SuccessBlock({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.green700.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            color: AppColors.green700,
            size: 28,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Check your inbox',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "The link expires in 1 hour. Didn't get it? Check spam, "
          "or try again from the login screen.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textMuted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: onBack,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.navy900,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Back to login',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
