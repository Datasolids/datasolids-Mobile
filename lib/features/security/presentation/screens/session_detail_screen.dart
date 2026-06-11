// Detail view for one active session — opened by tapping a row on the
// Active Sessions list. Shows the full device + location + activity
// metadata and a destructive "Sign out this device" CTA.
//
// We pass the LoginSessionItem in via `extra` on the go_router push so
// no extra round-trip is needed. If the user lands here via deep link
// the screen falls back to a friendly "Session not found" empty state.

import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:datasolids_mobile/features/security/data/dtos/security.dart';
import 'package:datasolids_mobile/features/security/data/security_api.dart';
import 'package:datasolids_mobile/features/security/presentation/controllers/security_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';


class SessionDetailScreen extends ConsumerStatefulWidget {
  const SessionDetailScreen({super.key, required this.session});
  final LoginSessionItem? session;

  @override
  ConsumerState<SessionDetailScreen> createState() =>
      _SessionDetailScreenState();
}

class _SessionDetailScreenState
    extends ConsumerState<SessionDetailScreen> {
  bool _isRevoking = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.navy900,
        leading: const BackButton(),
        title: Text(
          'Session details',
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
        child: s == null
            ? const Center(child: Text('Session not found.'))
            : _body(s),
      ),
    );
  }

  Widget _body(LoginSessionItem s) {
    final dfDateTime = DateFormat('MMM d, yyyy · h:mm a');
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Device hero
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: s.isCurrent
                  ? Border.all(color: AppColors.teal600, width: 1.5)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.navy700.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(_iconFor(s.deviceKind),
                      color: AppColors.navy700, size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  s.deviceLabel.isEmpty ? 'Unknown device' : s.deviceLabel,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy900,
                  ),
                ),
                if (s.isCurrent) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.teal600.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'THIS DEVICE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                        color: AppColors.teal600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Details card
          _DetailCard(rows: [
            _DetailRow(
              icon: Icons.location_on_outlined,
              label: 'Location',
              value: _locationValue(s),
            ),
            if ((s.ipAddress ?? '').isNotEmpty)
              _DetailRow(
                icon: Icons.public,
                label: 'IP address',
                value: s.ipAddress!,
              ),
            _DetailRow(
              icon: Icons.bolt_outlined,
              label: 'Last active',
              value: s.lastActiveAt == null
                  ? '—'
                  : dfDateTime.format(s.lastActiveAt!),
            ),
            _DetailRow(
              icon: Icons.login,
              label: 'Signed in',
              value: s.createdAt == null
                  ? '—'
                  : dfDateTime.format(s.createdAt!),
            ),
            if (s.userAgent.isNotEmpty)
              _DetailRow(
                icon: Icons.code,
                label: 'User agent',
                value: s.userAgent,
                multiline: true,
              ),
          ]),

          const SizedBox(height: 24),

          // Sign out CTA (suppressed on the caller's own session — they
          // should use the main Logout button so the keychain is wiped
          // and the app routes back to /login).
          if (!s.isCurrent)
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _isRevoking ? null : () => _confirmRevoke(s),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text(
                  'Sign out this device',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFA42D2D),
                  side: const BorderSide(color: Color(0xFFE0524F)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            )
          else
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
                      size: 18, color: AppColors.textMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "This is the device you're using right now. To sign out, tap Log out from the side menu.",
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
        ],
      ),
    );
  }

  Future<void> _confirmRevoke(LoginSessionItem s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out this device?'),
        content: Text(
          "Sign out ${s.deviceLabel.isEmpty ? 'this device' : s.deviceLabel}? "
          'It will need to sign in again to access your pod.',
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
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _isRevoking = true);
    try {
      await ref.read(securityApiProvider).revokeSession(s.id);
      ref.invalidate(activeSessionsProvider);
      ref.read(securityHomeControllerProvider.notifier).refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Signed out ${s.deviceLabel.isEmpty ? 'device' : s.deviceLabel}',
        ),
      ));
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/security/sessions');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRevoking = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not sign out device: $e'),
      ));
    }
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

  static String _locationValue(LoginSessionItem s) {
    if ((s.location ?? '').isNotEmpty) return s.location!;
    if ((s.city ?? '').isNotEmpty) return s.city!;
    return 'Unknown';
  }
}


// ─────────────────────────────────────────────────────────────────
// Small reusables
// ─────────────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.rows});
  final List<_DetailRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: AppColors.border.withOpacity(0.5),
              ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.multiline = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppColors.teal600.withOpacity(0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: AppColors.teal600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  value,
                  maxLines: multiline ? 6 : 1,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy900,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
