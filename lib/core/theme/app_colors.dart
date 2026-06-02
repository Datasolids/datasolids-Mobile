import 'package:flutter/material.dart';

/// Brand color tokens. Identical hex values to the webapp's CSS tokens
/// so screens look the same across platforms.
///
/// Do NOT use raw Color literals in feature code. Always go through
/// `Theme.of(context).extension<AppColors>()` or a domain-specific
/// helper. Direct imports of this class outside `core/theme` are a
/// lint smell.
class AppColors {
  AppColors._();

  // Primary teal — used for hero backgrounds, brand strokes.
  static const teal500 = Color(0xFF3AAFA9);
  static const teal600 = Color(0xFF319795);
  static const teal700 = Color(0xFF2A7B7B);

  // Navy — primary CTA fills, headlines.
  static const navy700 = Color(0xFF2C5282);
  static const navy900 = Color(0xFF1A365D);

  // Role accents.
  static const amber500 = Color(0xFFF1A208); // patient warmth
  static const purple700 = Color(0xFF6B46C1); // researcher

  // Semantic.
  static const green700 = Color(0xFF2F855A); // success
  static const orange600 = Color(0xFFDD6B20); // warning
  static const red700 = Color(0xFFC53030); // error / destructive

  // Surfaces (light theme).
  static const bgCream = Color(0xFFFAF7F2);
  static const surface = Color(0xFFFFFFFF);

  // Surfaces (dark theme).
  static const bgDark = Color(0xFF1A202C);
  static const surfaceDark = Color(0xFF2D3748);

  // Text.
  static const text = Color(0xFF1A202C);
  static const textMuted = Color(0xFF4A5568);
  static const textSubtle = Color(0xFF718096);
  static const textInverted = Color(0xFFF7FAFC);
  static const textMutedDark = Color(0xFFCBD5E0);

  // Border / hairline.
  static const border = Color(0xFFCBD5E0);
  static const borderDark = Color(0xFF4A5568);
}

/// ThemeExtension wrapper so feature widgets can read brand tokens
/// off the BuildContext without importing AppColors directly.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.teal,
    required this.navy,
    required this.patient,
    required this.researcher,
    required this.success,
    required this.warning,
    required this.danger,
    required this.border,
    required this.textMuted,
    required this.textSubtle,
  });

  final Color teal;
  final Color navy;
  final Color patient;
  final Color researcher;
  final Color success;
  final Color warning;
  final Color danger;
  final Color border;
  final Color textMuted;
  final Color textSubtle;

  static const light = AppPalette(
    teal: AppColors.teal500,
    navy: AppColors.navy900,
    patient: AppColors.amber500,
    researcher: AppColors.purple700,
    success: AppColors.green700,
    warning: AppColors.orange600,
    danger: AppColors.red700,
    border: AppColors.border,
    textMuted: AppColors.textMuted,
    textSubtle: AppColors.textSubtle,
  );

  static const dark = AppPalette(
    teal: AppColors.teal500,
    navy: AppColors.navy700,
    patient: AppColors.amber500,
    researcher: AppColors.purple700,
    success: AppColors.green700,
    warning: AppColors.orange600,
    danger: AppColors.red700,
    border: AppColors.borderDark,
    textMuted: AppColors.textMutedDark,
    textSubtle: AppColors.textMutedDark,
  );

  @override
  AppPalette copyWith({
    Color? teal,
    Color? navy,
    Color? patient,
    Color? researcher,
    Color? success,
    Color? warning,
    Color? danger,
    Color? border,
    Color? textMuted,
    Color? textSubtle,
  }) {
    return AppPalette(
      teal: teal ?? this.teal,
      navy: navy ?? this.navy,
      patient: patient ?? this.patient,
      researcher: researcher ?? this.researcher,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      border: border ?? this.border,
      textMuted: textMuted ?? this.textMuted,
      textSubtle: textSubtle ?? this.textSubtle,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      teal: Color.lerp(teal, other.teal, t)!,
      navy: Color.lerp(navy, other.navy, t)!,
      patient: Color.lerp(patient, other.patient, t)!,
      researcher: Color.lerp(researcher, other.researcher, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      border: Color.lerp(border, other.border, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textSubtle: Color.lerp(textSubtle, other.textSubtle, t)!,
    );
  }
}
