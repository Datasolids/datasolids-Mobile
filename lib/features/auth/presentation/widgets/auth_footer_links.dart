import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// "By continuing, you agree to our Terms of Service and Privacy
/// Policy." — shown on every auth screen.
class AuthFooterLinks extends StatelessWidget {
  const AuthFooterLinks({
    super.key,
    this.onTapTerms,
    this.onTapPrivacy,
  });

  final VoidCallback? onTapTerms;
  final VoidCallback? onTapPrivacy;

  @override
  Widget build(BuildContext context) {
    final link = TextStyle(
      fontSize: 12,
      color: Colors.white,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: Colors.white.withOpacity(0.8),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.92),
            height: 1.4,
          ),
          children: [
            const TextSpan(text: 'By continuing, you agree to our '),
            TextSpan(
              text: 'Terms of Service',
              style: link,
              recognizer: TapGestureRecognizer()..onTap = onTapTerms,
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: link,
              recognizer: TapGestureRecognizer()..onTap = onTapPrivacy,
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }
}
