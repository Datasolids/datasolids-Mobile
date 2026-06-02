import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum AuthMode { login, signup }

class AuthTabToggle extends StatelessWidget {
  const AuthTabToggle({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final AuthMode mode;
  final ValueChanged<AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCream,
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(child: _tab(AuthMode.login, 'Login')),
          Expanded(child: _tab(AuthMode.signup, 'Sign Up')),
        ],
      ),
    );
  }

  Widget _tab(AuthMode value, String label) {
    final active = mode == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.navy900 : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
