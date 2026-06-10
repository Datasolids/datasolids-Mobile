// Active sessions — shows every device with a live refresh token, with
// "THIS DEVICE" pill on the caller's own session and a danger CTA to
// sign out all other devices.

import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:datasolids_mobile/features/security/data/dtos/security.dart';
import 'package:datasolids_mobile/features/security/data/security_api.dart';
import 'package:datasolids_mobile/features/security/presentation/controllers/security_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class ActiveSessionsScreen extends ConsumerWidget {
  const ActiveSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activeSessionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.navy900,
        leading: const BackButton(),
        title: Text(
          'Active sessions',
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
          onRefresh: () async => ref.invalidate(activeSessionsProvider),
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _ErrorBlock(
              onRetry: () => ref.invalidate(activeSessionsProvider),
            ),
            data: (sessions) => _Body(sessions: sessions, ref: ref),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.sessions, required this.ref});
  final List<LoginSessionItem> sessions;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'You are currently signed in to '
            '${sessions.length} device${sessions.length == 1 ? '' : 's'}.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          if (sessions.isEmpty)
            _EmptyBlock()
          else
            for (final s in sessions) ...[
              _SessionCard(session: s),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 16),
          // Safety warning
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF1F4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    color: AppColors.textMuted, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "If you don't recognize a device or location, sign out immediately and change your password.",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (sessions.where((s) => !s.isCurrent).isNotEmpty)
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: () => _confirmRevokeAll(context, ref),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFA42D2D),
                  side: const BorderSide(color: Color(0xFFE0524F)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Sign out all other devices',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmRevokeAll(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out other devices?'),
        content: const Text(
          "Every other phone, tablet, or browser signed in to your pod will be signed out immediately. You'll stay signed in here.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFA42D2D),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out all'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      final count =
          await ref.read(securityApiProvider).revokeAllOtherSessions();
      ref.invalidate(activeSessionsProvider);
      ref.read(securityHomeControllerProvider.notifier).refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Signed out $count other '
                        'device${count == 1 ? '' : 's'}'),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not sign out other devices: $e'),
        ));
      }
    }
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});
  final LoginSessionItem session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: session.isCurrent
            ? Border.all(color: AppColors.teal600, width: 1.5)
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
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.navy700.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _iconFor(session.deviceKind),
              color: AppColors.navy700,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.deviceLabel.isEmpty
                      ? 'Unknown device'
                      : session.deviceLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _locationLine(session),
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
          if (session.isCurrent) _ThisDevicePill(),
        ],
      ),
    );
  }

  static IconData _iconFor(String kind) {
    final k = kind.toLowerCase();
    if (k.contains('ios')) return Icons.phone_iphone;
    if (k.contains('ipad')) return Icons.tablet_mac;
    if (k.contains('android')) return Icons.phone_android;
    if (k.contains('web')) return Icons.laptop_mac;
    if (k.contains('mac')) return Icons.laptop_mac;
    if (k.contains('windows')) return Icons.laptop_windows;
    return Icons.devices_other;
  }

  static String _locationLine(LoginSessionItem s) {
    final pieces = <String>[];
    if ((s.city ?? '').isNotEmpty) pieces.add(s.city!);
    if ((s.ipAddress ?? '').isNotEmpty && (s.city ?? '').isEmpty) {
      pieces.add(s.ipAddress!);
    }
    pieces.add(_relativeTime(s.lastActiveAt));
    return pieces.join(' · ');
  }

  static String _relativeTime(DateTime? t) {
    if (t == null) return '';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Active now';
    if (d.inMinutes < 60) return 'Active ${d.inMinutes}m ago';
    if (d.inHours < 24) return 'Active ${d.inHours}h ago';
    if (d.inDays < 7) return 'Active ${d.inDays}d ago';
    return 'Active ${(d.inDays / 7).floor()}w ago';
  }
}

class _ThisDevicePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.teal600.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'THIS DEVICE',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: AppColors.teal600,
        ),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.devices_outlined,
              color: AppColors.textMuted, size: 32),
          const SizedBox(height: 10),
          Text(
            'No active sessions',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.navy900,
            ),
          ),
        ],
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
          Text("Couldn't load sessions",
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
