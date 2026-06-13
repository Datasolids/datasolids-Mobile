// In-app banner toast — single card matching the design.
//
// Layout (from the design spec):
//   ┌────────────────────────────────────────┐
//   │  ⊙ Title                          ✕    │
//   │    Body text up to two lines           │
//   └────────────────────────────────────────┘
//
// White card, soft shadow, circle-outline icon on the left, title +
// body in the middle, dismiss X on the right. Tappable everywhere
// except the X to deep-link into the notification detail.

import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:flutter/material.dart';


/// A single banner row. Stateless — animation + lifecycle is owned by
/// [InAppBannerOverlay] in the service file.
class InAppBanner extends StatelessWidget {
  const InAppBanner({
    super.key,
    required this.title,
    required this.body,
    required this.icon,
    required this.iconColor,
    this.onTap,
    this.onDismiss,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.border.withOpacity(0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circle-outline icon
              Container(
                width: 36, height: 36,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: iconColor.withOpacity(0.35), width: 1.5,
                  ),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              // Title + body
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              // Dismiss X
              IconButton(
                onPressed: onDismiss,
                icon: Icon(Icons.close,
                    size: 18, color: AppColors.textMuted),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                splashRadius: 18,
                tooltip: 'Dismiss',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
