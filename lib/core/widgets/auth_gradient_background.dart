import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Navy-to-teal diagonal gradient used by every unauthenticated
/// screen (splash, login, signup, forgot password). Matches the
/// Figma design's hero background.
class AuthGradientBackground extends StatelessWidget {
  const AuthGradientBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.navy900,
            AppColors.teal700,
            AppColors.teal500,
          ],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: child,
    );
  }
}
