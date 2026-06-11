// Single-notification view — /notifications/{id}
//
// Big-rounded card with a kind-themed hero icon, eyebrow label, title,
// timestamp, body. Primary CTA below the card routes based on kind
// (lab → lab detail, sync → home, signin → security home, etc.). A
// "Mark unread / Archive" pair sits below and an "END-TO-END
// ENCRYPTED" footer reassures the user.

import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:datasolids_mobile/features/notifications/data/dtos/notification.dart';
import 'package:datasolids_mobile/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';


class NotificationDetailScreen extends ConsumerWidget {
  const NotificationDetailScreen({super.key, required this.notificationId});
  final String notificationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationDetailProvider(notificationId));

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.navy900,
        leading: const BackButton(),
        actions: [
          IconButton(
            tooltip: 'Archive',
            onPressed: () {
              final notif = async.valueOrNull;
              if (notif == null) return;
              _archive(context, ref, notif);
            },
            icon: const Icon(Icons.inventory_2_outlined, size: 22),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text("Couldn't load notification"),
        ),
        data: (notif) => _body(context, ref, notif),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, NotificationItem n) {
    final dfLong = DateFormat('MMMM d, yyyy · h:mm a');
    final (icon, color, bg) = _heroStyleFor(n.kind);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero card
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: bg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 36, color: color),
                ),
                const SizedBox(height: 16),
                Text(
                  n.kind.eyebrowLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  n.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dfLong.format(n.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    n.body,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.navy900,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Primary CTA
          if (_primaryCta(n.kind) != null) ...[
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: () => _primaryCta(n.kind)!(context, n),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: Icon(_primaryCtaIcon(n.kind), size: 18),
                label: Text(
                  _primaryCtaLabel(n.kind),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Mark unread + Archive pair
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    if (n.isRead) {
                      await ref
                          .read(notificationsFeedControllerProvider.notifier)
                          .markUnread(n.id);
                    } else {
                      await ref
                          .read(notificationsFeedControllerProvider.notifier)
                          .markRead(n.id);
                    }
                    ref.invalidate(notificationDetailProvider(n.id));
                  },
                  icon: Icon(
                    n.isRead
                        ? Icons.mark_email_unread_outlined
                        : Icons.mark_email_read_outlined,
                    size: 16,
                  ),
                  label: Text(
                    n.isRead ? 'Mark unread' : 'Mark read',
                    style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy900,
                    side: BorderSide(
                      color: AppColors.border.withOpacity(0.8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _archive(context, ref, n),
                  icon: const Icon(Icons.inventory_2_outlined, size: 16),
                  label: const Text(
                    'Archive',
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy900,
                    side: BorderSide(
                      color: AppColors.border.withOpacity(0.8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // End-to-end encrypted footer
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline,
                    size: 13, color: AppColors.textSubtle),
                const SizedBox(width: 6),
                Text(
                  'END-TO-END ENCRYPTED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.textSubtle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Per-kind routing
  // ─────────────────────────────────────────────────────────────────

  void Function(BuildContext, NotificationItem)? _primaryCta(
    NotificationKind k,
  ) {
    switch (k) {
      case NotificationKind.labResult:
        return (ctx, n) {
          final id = n.data['diagnostic_report_id']?.toString();
          if (id != null && id.isNotEmpty) {
            ctx.push('/clinical/diagnostic-report/$id');
          }
        };
      case NotificationKind.syncCompleted:
        return (ctx, _) => ctx.go('/home');
      case NotificationKind.securitySignin:
        return (ctx, _) => ctx.push('/security/sessions');
      case NotificationKind.grantAccessed:
        return (ctx, _) {
          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
            content: Text('Grants surface coming soon.'),
          ));
        };
      case NotificationKind.researchOpportunity:
      case NotificationKind.appUpdate:
      case NotificationKind.generic:
        return null;
    }
  }

  String _primaryCtaLabel(NotificationKind k) {
    switch (k) {
      case NotificationKind.labResult: return 'View results in My Pod';
      case NotificationKind.syncCompleted: return 'Open my pod';
      case NotificationKind.securitySignin: return 'Review active sessions';
      case NotificationKind.grantAccessed: return 'See who has access';
      default: return 'Open';
    }
  }

  IconData _primaryCtaIcon(NotificationKind k) {
    switch (k) {
      case NotificationKind.labResult: return Icons.layers_outlined;
      case NotificationKind.syncCompleted: return Icons.layers_outlined;
      case NotificationKind.securitySignin: return Icons.shield_outlined;
      case NotificationKind.grantAccessed: return Icons.share_outlined;
      default: return Icons.open_in_new;
    }
  }

  static (IconData, Color, Color) _heroStyleFor(NotificationKind k) {
    switch (k) {
      case NotificationKind.securitySignin:
        return (Icons.shield_outlined,
                AppColors.navy900, AppColors.navy700.withOpacity(0.10));
      case NotificationKind.syncCompleted:
        return (Icons.check_circle_outline,
                AppColors.navy900, AppColors.navy700.withOpacity(0.10));
      case NotificationKind.labResult:
        return (Icons.science_outlined,
                AppColors.teal600, AppColors.teal600.withOpacity(0.12));
      case NotificationKind.grantAccessed:
        return (Icons.share_outlined,
                AppColors.navy900, AppColors.navy700.withOpacity(0.10));
      case NotificationKind.researchOpportunity:
        return (Icons.auto_awesome,
                const Color(0xFF7C5CFC),
                const Color(0xFF7C5CFC).withOpacity(0.12));
      case NotificationKind.appUpdate:
        return (Icons.settings_outlined,
                AppColors.navy900, AppColors.navy700.withOpacity(0.10));
      case NotificationKind.generic:
        return (Icons.notifications_outlined,
                AppColors.navy900, AppColors.navy700.withOpacity(0.10));
    }
  }

  Future<void> _archive(
    BuildContext context,
    WidgetRef ref,
    NotificationItem n,
  ) async {
    await ref
        .read(notificationsFeedControllerProvider.notifier)
        .archive(n.id);
    if (!context.mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/notifications');
    }
  }
}
