import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Datasolids brand mark — a small white rounded card with a teal
/// shield-and-check inside. Reused on splash, login, signup, empty
/// states. ALWAYS use this widget; never hand-roll the shape.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 64});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.verified_user_outlined,
          size: size * 0.55,
          color: AppColors.teal500,
        ),
      ),
    );
  }
}
