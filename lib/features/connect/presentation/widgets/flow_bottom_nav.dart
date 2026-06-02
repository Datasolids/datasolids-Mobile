// Visual bottom navigation for the pushed Connect-EHR flow screens, matching
// the Home design. These screens are pushed on top of the tabbed Home, so any
// tab tap returns to Home (the tab itself is selected back on Home).

import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FlowBottomNav extends StatelessWidget {
  const FlowBottomNav({super.key, this.activeIndex = 1});

  /// 0 Home · 1 My Pod · 2 Grants · 3 Profile (defaults to My Pod, matching
  /// where the connect flow lives in the IA).
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _item(context, Icons.home_outlined, Icons.home, 'HOME', 0),
              _item(context, Icons.dataset_linked_outlined,
                  Icons.dataset_linked, 'MY POD', 1),
              _item(context, Icons.shield_outlined, Icons.shield, 'GRANTS', 2),
              _item(context, Icons.person_outline, Icons.person, 'PROFILE', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, IconData iconActive,
      String label, int index) {
    final selected = index == activeIndex;
    final color = selected ? AppColors.teal600 : AppColors.textSubtle;
    return Expanded(
      child: InkWell(
        onTap: () => context.go('/home'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? iconActive : icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
