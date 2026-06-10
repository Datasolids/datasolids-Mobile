// Security activity log — every UserAuditEvent the caller can see.
// Grouped by day (TODAY, YESTERDAY, This Week, Earlier).

import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:datasolids_mobile/features/security/data/dtos/security.dart';
import 'package:datasolids_mobile/features/security/presentation/controllers/security_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class SecurityActivityScreen extends ConsumerWidget {
  const SecurityActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(securityEventsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.navy900,
        leading: const BackButton(),
        title: Text(
          'Activity log',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.navy900,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.teal600,
          onRefresh: () async => ref.invalidate(securityEventsProvider),
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _ErrorBlock(
              onRetry: () => ref.invalidate(securityEventsProvider),
            ),
            data: (events) => events.isEmpty
                ? _EmptyBlock()
                : _Body(events: events),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.events});
  final List<SecurityEventItem> events;

  @override
  Widget build(BuildContext context) {
    // Group by day bucket.
    final grouped = _groupByDay(events);

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      itemCount: grouped.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Text(
              'Every security event is logged for your transparency.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
          );
        }
        final entry = grouped[i - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10, left: 4),
                child: Text(
                  entry.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    color: AppColors.textSubtle,
                  ),
                ),
              ),
              for (var j = 0; j < entry.items.length; j++) ...[
                _EventCard(event: entry.items[j]),
                if (j < entry.items.length - 1) const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }

  static List<_DayGroup> _groupByDay(List<SecurityEventItem> events) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final groups = <String, _DayGroup>{};

    String labelFor(DateTime? t) {
      if (t == null) return 'Undated';
      final d = DateTime(t.year, t.month, t.day);
      final diff = todayDate.difference(d).inDays;
      if (diff == 0) return 'TODAY';
      if (diff == 1) return 'YESTERDAY';
      if (diff < 7) return 'THIS WEEK';
      return 'EARLIER';
    }

    for (final ev in events) {
      final lbl = labelFor(ev.createdAt);
      groups.putIfAbsent(lbl, () => _DayGroup(lbl, [])).items.add(ev);
    }
    // Preserve a logical order.
    const order = ['TODAY', 'YESTERDAY', 'THIS WEEK', 'EARLIER', 'Undated'];
    return [
      for (final k in order)
        if (groups[k] != null) groups[k]!,
    ];
  }
}

class _DayGroup {
  _DayGroup(this.label, this.items);
  final String label;
  final List<SecurityEventItem> items;
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});
  final SecurityEventItem event;

  @override
  Widget build(BuildContext context) {
    final (icon, iconBg, iconFg) = _iconFor(event.eventType);
    final (title, subtitle) = _displayFor(event);
    final showReview = event.eventType == 'login_success'
        && (event.metadata['new_device'] == true);

    return InkWell(
      onTap: () => _showDetail(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconFg, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy900,
                          ),
                        ),
                      ),
                      if (showReview)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4DA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'REVIEW',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: Color(0xFFA15C00),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: AppColors.textSubtle),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                _displayFor(event).$1,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy900,
                ),
              ),
              const SizedBox(height: 10),
              _DetailRow('Event type', event.eventType),
              if ((event.ipAddress ?? '').isNotEmpty)
                _DetailRow('IP address', event.ipAddress!),
              if ((event.userAgent ?? '').isNotEmpty)
                _DetailRow('Device', event.userAgent!, multiline: true),
              if (event.createdAt != null)
                _DetailRow('Time', event.createdAt!.toString().substring(0, 19)),
              if (event.metadata.isNotEmpty)
                _DetailRow('Metadata', event.metadata.toString(),
                            multiline: true),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Event-type display tables ────────────────────────────────

  static (IconData, Color, Color) _iconFor(String type) {
    switch (type) {
      case 'login_success':
        return (Icons.login, const Color(0xFFE6F4EA),
                const Color(0xFF1B7F3A));
      case 'login_failure':
        return (Icons.error_outline, const Color(0xFFFCE4E4),
                const Color(0xFFA42D2D));
      case 'logout':
        return (Icons.logout, const Color(0xFFEEF1F4),
                AppColors.navy700);
      case 'mfa_enabled':
      case 'mfa_challenge_success':
        return (Icons.shield_outlined, const Color(0xFFE6F4EA),
                const Color(0xFF1B7F3A));
      case 'mfa_challenge_failure':
      case 'mfa_disabled':
        return (Icons.shield_outlined, const Color(0xFFFCE4E4),
                const Color(0xFFA42D2D));
      case 'password_changed':
        return (Icons.lock_outline, const Color(0xFFE6F0FB),
                const Color(0xFF1B5FA8));
      case 'account_locked':
        return (Icons.lock, const Color(0xFFFCE4E4),
                const Color(0xFFA42D2D));
      case 'email_verified':
        return (Icons.mark_email_read_outlined, const Color(0xFFE6F4EA),
                const Color(0xFF1B7F3A));
      case 'grant_used':
      case 'grant_created':
        return (Icons.share_outlined, const Color(0xFFE6F0FB),
                const Color(0xFF1B5FA8));
      case 'grant_revoked':
        return (Icons.block, const Color(0xFFFCE4E4),
                const Color(0xFFA42D2D));
      default:
        return (Icons.bolt_outlined, const Color(0xFFEEF1F4),
                AppColors.textMuted);
    }
  }

  static (String, String) _displayFor(SecurityEventItem e) {
    String t = '';
    switch (e.eventType) {
      case 'login_success':
        t = 'Successful sign-in'; break;
      case 'login_failure':
        t = 'Failed sign-in attempt'; break;
      case 'logout':
        t = 'Signed out'; break;
      case 'mfa_enabled':
        t = 'MFA enabled'; break;
      case 'mfa_disabled':
        t = 'MFA disabled'; break;
      case 'mfa_challenge_success':
        t = 'MFA verification passed'; break;
      case 'mfa_challenge_failure':
        t = 'MFA verification failed'; break;
      case 'password_changed':
        t = 'Password changed'; break;
      case 'account_locked':
        t = 'Account locked'; break;
      case 'email_verified':
        t = 'Email verified'; break;
      case 'grant_created':
        t = 'Data grant created'; break;
      case 'grant_revoked':
        t = 'Data grant revoked'; break;
      case 'grant_used':
        t = 'Pod accessed'; break;
      default:
        t = e.eventType.replaceAll('_', ' ');
    }
    final subtitle = _timeAndDevice(e);
    return (t, subtitle);
  }

  static String _timeAndDevice(SecurityEventItem e) {
    final pieces = <String>[];
    final ua = (e.userAgent ?? '').toLowerCase();
    String device = '';
    if (ua.contains('iphone')) device = 'iPhone';
    else if (ua.contains('ipad')) device = 'iPad';
    else if (ua.contains('android')) device = 'Android';
    else if (ua.contains('mac')) device = 'macOS';
    else if (ua.contains('windows')) device = 'Windows';
    if (device.isNotEmpty) pieces.add(device);
    if (e.createdAt != null) {
      pieces.add(_shortTime(e.createdAt!));
    }
    return pieces.join(' · ');
  }

  static String _shortTime(DateTime t) {
    final local = t.toLocal();
    final hour = local.hour > 12
        ? local.hour - 12
        : (local.hour == 0 ? 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final amPm = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value, {this.multiline = false});
  final String label;
  final String value;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: AppColors.textSubtle,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              maxLines: multiline ? null : 2,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.navy900,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, color: AppColors.textMuted, size: 32),
            const SizedBox(height: 10),
            Text(
              'No activity in the past 90 days',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.navy900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined,
              color: AppColors.textMuted, size: 32),
          const SizedBox(height: 10),
          Text("Couldn't load activity",
              style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: AppColors.navy900,
              )),
          TextButton(
            onPressed: onRetry,
            child: Text('Retry',
                style: TextStyle(
                  color: AppColors.teal600,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ),
    );
  }
}
