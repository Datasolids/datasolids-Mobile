// Notifications list — /notifications
//
// Matches the design: cream background, grouped by TODAY / YESTERDAY /
// EARLIER, unread rows get a teal-tinted left border and a small dot
// next to the title, "Mark all read" double-check icon in the top
// right when there's at least one unread.
//
// Tap a row → /notifications/{id}. Pull-to-refresh re-fetches the feed.
// Empty state: bell glyph + "You're all caught up" + manage prefs link.

import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:datasolids_mobile/features/notifications/data/dtos/notification.dart';
import 'package:datasolids_mobile/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


class NotificationsListScreen extends ConsumerWidget {
  const NotificationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsFeedControllerProvider);
    final ctrl = ref.read(notificationsFeedControllerProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.navy900,
        leading: const BackButton(),
        title: Row(
          children: [
            Text(
              'Notifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.navy900,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 8),
            if (state.unreadCount > 0)
              _UnreadBadge(count: state.unreadCount),
          ],
        ),
        actions: [
          if (state.unreadCount > 0)
            IconButton(
              tooltip: 'Mark all read',
              onPressed: () => ctrl.markAllRead(),
              icon: Icon(Icons.done_all,
                  color: AppColors.teal600, size: 22),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.teal600,
        onRefresh: ctrl.refresh,
        child: _buildBody(context, state, ctrl),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    NotificationsFeedState state,
    NotificationsFeedController ctrl,
  ) {
    if (state.items.isEmpty && state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.items.isEmpty && state.errorMessage != null) {
      return _ErrorBlock(onRetry: ctrl.refresh);
    }
    if (state.items.isEmpty) {
      return const _EmptyState();
    }

    final groups = _groupByDay(state.items);
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      itemCount: groups.length,
      itemBuilder: (context, i) {
        final group = groups[i];
        return Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 0, 0, 8),
                child: Text(
                  group.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              for (final n in group.items) ...[
                _NotificationCard(
                  notification: n,
                  onTap: () async {
                    if (!n.isRead) await ctrl.markRead(n.id);
                    if (!context.mounted) return;
                    context.push('/notifications/${n.id}');
                  },
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }
}


// ─────────────────────────────────────────────────────────────────
// Day-bucket grouping
// ─────────────────────────────────────────────────────────────────

class _Group {
  const _Group(this.label, this.items);
  final String label;
  final List<NotificationItem> items;
}

List<_Group> _groupByDay(List<NotificationItem> items) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final weekAgo = today.subtract(const Duration(days: 7));

  final todayList = <NotificationItem>[];
  final yesterdayList = <NotificationItem>[];
  final thisWeekList = <NotificationItem>[];
  final earlierList = <NotificationItem>[];

  for (final n in items) {
    final d = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
    if (!d.isBefore(today)) {
      todayList.add(n);
    } else if (!d.isBefore(yesterday)) {
      yesterdayList.add(n);
    } else if (!d.isBefore(weekAgo)) {
      thisWeekList.add(n);
    } else {
      earlierList.add(n);
    }
  }

  return [
    if (todayList.isNotEmpty) _Group('TODAY', todayList),
    if (yesterdayList.isNotEmpty) _Group('YESTERDAY', yesterdayList),
    if (thisWeekList.isNotEmpty) _Group('THIS WEEK', thisWeekList),
    if (earlierList.isNotEmpty) _Group('EARLIER', earlierList),
  ];
}


// ─────────────────────────────────────────────────────────────────
// Notification row
// ─────────────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });
  final NotificationItem notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: unread
                ? Border(left: BorderSide(
                    color: AppColors.teal600, width: 3))
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _KindIcon(kind: notification.kind),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy900,
                            ),
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 7, height: 7,
                            decoration: BoxDecoration(
                              color: AppColors.teal600,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                        const SizedBox(width: 6),
                        Text(
                          _relativeAge(notification.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _relativeAge(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'NOW';
    if (d.inMinutes < 60) return '${d.inMinutes}M AGO';
    if (d.inHours < 24) return '${d.inHours}H AGO';
    if (d.inDays < 7) return '${d.inDays}D AGO';
    return '${(d.inDays / 7).floor()}W AGO';
  }
}

class _KindIcon extends StatelessWidget {
  const _KindIcon({required this.kind});
  final NotificationKind kind;

  @override
  Widget build(BuildContext context) {
    final (icon, color, bg) = _styleFor(kind);
    return Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }

  static (IconData, Color, Color) _styleFor(NotificationKind k) {
    switch (k) {
      case NotificationKind.securitySignin:
        return (Icons.shield_outlined,
                AppColors.navy700, AppColors.navy700.withOpacity(0.10));
      case NotificationKind.syncCompleted:
        return (Icons.check_circle_outline,
                AppColors.navy700, AppColors.navy700.withOpacity(0.10));
      case NotificationKind.labResult:
        return (Icons.science_outlined,
                AppColors.teal600, AppColors.teal600.withOpacity(0.12));
      case NotificationKind.grantAccessed:
        return (Icons.share_outlined,
                AppColors.navy700, AppColors.navy700.withOpacity(0.10));
      case NotificationKind.researchOpportunity:
        return (Icons.auto_awesome,
                const Color(0xFF7C5CFC),
                const Color(0xFF7C5CFC).withOpacity(0.12));
      case NotificationKind.appUpdate:
        return (Icons.settings_outlined,
                AppColors.navy700, AppColors.navy700.withOpacity(0.10));
      case NotificationKind.generic:
        return (Icons.notifications_outlined,
                AppColors.navy700, AppColors.navy700.withOpacity(0.10));
    }
  }
}


class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.teal600.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count UNREAD',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: AppColors.teal600,
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────
// Empty / error
// ─────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
      children: [
        Center(
          child: Container(
            width: 96, height: 96,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.notifications_outlined,
                    size: 40, color: AppColors.navy900),
                Positioned(
                  right: 16, bottom: 18,
                  child: Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.teal600,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Center(
          child: Text(
            "You're all caught up",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.navy900,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            "We'll let you know when something needs your attention, like new results or sync updates.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Center(
          child: TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Notification preferences are coming soon.'),
              ));
            },
            icon: Icon(Icons.tune,
                size: 16, color: AppColors.teal600),
            label: Text(
              'Manage notification preferences  →',
              style: TextStyle(
                color: AppColors.teal600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.onRetry});
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 40),
      children: [
        Center(
          child: Icon(Icons.cloud_off_outlined,
              size: 32, color: AppColors.textMuted),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text("Couldn't load notifications",
              style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: AppColors.navy900,
              )),
        ),
        Center(
          child: TextButton(
            onPressed: () => onRetry(),
            child: Text('Retry',
                style: TextStyle(
                  color: AppColors.teal600,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ),
      ],
    );
  }
}
