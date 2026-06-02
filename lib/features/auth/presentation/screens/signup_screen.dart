// Standalone signup screen — "Create Pod / Initialize Your Health Node".
// Posts to: POST /api/v1/auth/signup/patient/
//
// Phone field uses country_code_picker for the country selector and a
// plain TextField for the local number; we concatenate to E.164 before
// sending. On success we route back to /login with a confirmation banner.

import 'package:country_code_picker/country_code_picker.dart';
import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:datasolids_mobile/core/widgets/auth_input_field.dart';
import 'package:datasolids_mobile/features/auth/presentation/controllers/signup_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _acceptTerms = false;
  bool _showTermsError = false;
  String _dialCode = '+1';

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String _composedPhone() {
    final local = _phoneCtrl.text.replaceAll(RegExp(r'[\s\-\(\)]+'), '');
    if (local.isEmpty) return '';
    return '$_dialCode$local';
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState?.validate() ?? false;
    if (!_acceptTerms) {
      setState(() => _showTermsError = true);
    }
    if (!formOk || !_acceptTerms) return;

    await ref.read(signupControllerProvider.notifier).submit(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          acceptTerms: _acceptTerms,
          phone: _composedPhone().isEmpty ? null : _composedPhone(),
        );

    if (!mounted) return;
    final state = ref.read(signupControllerProvider);
    if (state.succeeded) {
      // Hand control back to the login screen with a flag the login
      // screen reads to show a confirmation banner.
      context.go('/login', extra: {
        'justSignedUp': true,
        'email': _emailCtrl.text.trim(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signupControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.navy900,
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
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            child: Column(
              children: [
                // Back button row.
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon:
                        const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/login'),
                  ),
                ),

                // ─── Brand mark ─────────────────────────
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.20),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.person_add_alt_1_outlined,
                    color: AppColors.teal500,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Create Pod',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'INITIALIZE YOUR HEALTH NODE',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.65),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 22),

                // ─── White card ─────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                  decoration: BoxDecoration(
                    color: AppColors.bgCream,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // First + last name in a row.
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AuthInputField(
                                label: 'First name',
                                controller: _firstNameCtrl,
                                hintText: 'John',
                                textInputAction: TextInputAction.next,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required.'
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AuthInputField(
                                label: 'Last name',
                                controller: _lastNameCtrl,
                                hintText: 'Doe',
                                textInputAction: TextInputAction.next,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required.'
                                        : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        AuthInputField(
                          label: 'Email address',
                          controller: _emailCtrl,
                          icon: Icons.mail_outline,
                          hintText: 'john@example.com',
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: TextInputAction.next,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 16),

                        // ─── Phone with country picker ─────────
                        const _SectionLabel(label: 'Phone number'),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Country code picker — styled to match
                            // the rest of the form.
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: CountryCodePicker(
                                onChanged: (c) => setState(
                                    () => _dialCode = c.dialCode ?? '+1'),
                                initialSelection: 'US',
                                favorite: const ['+1', 'US', 'IN', 'GB'],
                                showCountryOnly: false,
                                showFlag: true,
                                showFlagDialog: true,
                                showOnlyCountryWhenClosed: false,
                                alignLeft: false,
                                padding: EdgeInsets.zero,
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w600,
                                ),
                                dialogTextStyle: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.text,
                                ),
                                searchStyle: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.text,
                                ),
                                flagWidth: 22,
                                boxDecoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                autofillHints: const [
                                  AutofillHints.telephoneNumber,
                                ],
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.text,
                                ),
                                decoration: InputDecoration(
                                  hintText: '555-0123',
                                  hintStyle: const TextStyle(
                                    color: AppColors.textSubtle,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.phone_outlined,
                                    color: AppColors.textMuted,
                                    size: 20,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: AppColors.border,
                                      width: 1,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: AppColors.border,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: AppColors.teal500,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        AuthInputField(
                          label: 'Password',
                          controller: _passwordCtrl,
                          icon: Icons.lock_outline,
                          obscureText: _obscure,
                          autofillHints: const [AutofillHints.newPassword],
                          textInputAction: TextInputAction.done,
                          validator: _validatePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            'Must be at least 12 characters.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ─── Terms checkbox ─────────────────
                        InkWell(
                          onTap: () => setState(() {
                            _acceptTerms = !_acceptTerms;
                            if (_acceptTerms) _showTermsError = false;
                          }),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _acceptTerms,
                                    onChanged: (v) => setState(() {
                                      _acceptTerms = v ?? false;
                                      if (_acceptTerms) {
                                        _showTermsError = false;
                                      }
                                    }),
                                    activeColor: AppColors.teal500,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity:
                                        VisualDensity.compact,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.only(top: 2),
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.35,
                                          color: AppColors.textMuted,
                                        ),
                                        children: [
                                          const TextSpan(
                                            text: 'I agree to the ',
                                          ),
                                          TextSpan(
                                            text: 'Terms',
                                            style: TextStyle(
                                              color: AppColors.teal600,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const TextSpan(text: ' and '),
                                          TextSpan(
                                            text: 'Privacy Policy',
                                            style: TextStyle(
                                              color: AppColors.teal600,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const TextSpan(text: '.'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_showTermsError && !_acceptTerms) ...[
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 34),
                            child: Text(
                              'You must accept the Terms to continue.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.red700,
                              ),
                            ),
                          ),
                        ],

                        if (state.errorMessage != null) ...[
                          const SizedBox(height: 14),
                          _ErrorChip(message: state.errorMessage!),
                        ],

                        const SizedBox(height: 22),
                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: state.isSubmitting ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.teal500,
                              disabledBackgroundColor:
                                  AppColors.teal500.withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
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
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: const [
                                      Text(
                                        'Initialize Node',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        Center(
                          child: GestureDetector(
                            onTap: () => context.go('/login'),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                                children: [
                                  const TextSpan(
                                      text: 'Already a member?  '),
                                  TextSpan(
                                    text: 'Sign In',
                                    style: TextStyle(
                                      color: AppColors.teal600,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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

  static String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Required.';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok ? null : 'Enter a valid email address.';
  }

  static String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Required.';
    if (v.length < 12) return 'Minimum 12 characters.';
    return null;
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: AppColors.textSubtle,
      ),
    );
  }
}

class _ErrorChip extends StatelessWidget {
  const _ErrorChip({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.red700.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.red700.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.red700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.red700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
