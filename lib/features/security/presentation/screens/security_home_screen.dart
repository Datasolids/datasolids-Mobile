// Security home — matches the "Security: Home" design.
// Header + reassurance line, six tappable rows in one card, security
// posture explainer at the bottom.

import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:datasolids_mobile/features/security/data/dtos/security.dart';
import 'package:datasolids_mobile/features/security/presentation/controllers/security_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


class SecurityHomeScreen extends ConsumerWidget {
  const SecurityHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(securityHomeControllerProvider);
    final notifier = ref.read(securityHomeControllerProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.teal600,
          onRefresh: notifier.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(),
                const SizedBox(height: 22),
                if (state.home == null && state.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (state.home == null)
                  _ErrorBlock(onRetry: notifier.refresh)
                else ...[
                  if (state.home!.pastGrace) ...[
                    _MfaUrgentBanner(),
                    const SizedBox(height: 12),
                  ],
                  _SecurityRows(home: state.home!),
                  const SizedBox(height: 16),
                  _SecurityNote(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleBackButton(onTap: () => Navigator.of(context).pop()),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Security',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Your pod is encrypted and access is logged.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 26,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withOpacity(0.6)),
        ),
        child: Icon(Icons.arrow_back, color: AppColors.navy900, size: 20),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// MFA urgent banner (past grace deadline)
// ─────────────────────────────────────────────────────────────────

class _MfaUrgentBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4E4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFA42D2D), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Two-factor authentication is required',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFA42D2D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "You'll need to set up MFA to continue using Datasolids.",
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFFA42D2D).withOpacity(0.85),
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

// ─────────────────────────────────────────────────────────────────
// Rows
// ─────────────────────────────────────────────────────────────────

class _SecurityRows extends StatelessWidget {
  const _SecurityRows({required this.home});
  final SecurityHome home;

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
          _Row(
            icon: Icons.lock_outline,
            iconColor: AppColors.navy700,
            title: 'Sign-in method',
            subtitle: 'Password${home.mfaEnabled ? ", MFA on" : ""}',
            onTap: () => context.push('/security/password'),
          ),
          _Divider(),
          _Row(
            icon: Icons.refresh_rounded,
            iconColor: AppColors.navy700,
            title: 'Reset password',
            subtitle: 'Update your account credentials',
            onTap: () => context.push('/security/password'),
          ),
          _Divider(),
          _Row(
            icon: Icons.shield_outlined,
            iconColor: AppColors.teal600,
            title: 'Two-factor authentication',
            subtitle: home.mfaEnabled ? 'Authenticator app' : 'Not set up',
            trailingPill: home.mfaEnabled
                ? const _Pill(label: 'ON',
                             bg: Color(0xFFE6F4EA), fg: Color(0xFF1B7F3A))
                : const _Pill(label: 'OFF',
                             bg: Color(0xFFFFF4DA), fg: Color(0xFFA15C00)),
            onTap: () => context.push(
              home.mfaEnabled ? '/security/mfa-status' : '/security/mfa-choose',
            ),
          ),
          _Divider(),
          _Row(
            icon: Icons.devices_outlined,
            iconColor: AppColors.navy700,
            title: 'Active sessions',
            subtitle:
                '${home.activeSessionsCount} device${home.activeSessionsCount == 1 ? '' : 's'}',
            onTap: () => context.push('/security/sessions'),
          ),
          _Divider(),
          _Row(
            icon: Icons.show_chart,
            iconColor: AppColors.navy700,
            title: 'Recent activity',
            subtitle: 'View security log',
            onTap: () => context.push('/security/activity'),
          ),
          _Divider(),
          _Row(
            icon: Icons.vpn_key_outlined,
            iconColor: AppColors.navy700,
            title: 'Recovery codes',
            subtitle: home.recoveryCodesGenerated
                ? '${home.recoveryCodesUnusedCount} unused'
                : 'Not generated',
            onTap: () => context.push('/security/recovery-codes'),
          ),
          _Divider(),
          _Row(
            icon: Icons.delete_outline,
            iconColor: const Color(0xFFA42D2D),
            title: 'Delete account',
            subtitle: 'Permanently remove data',
            titleColor: const Color(0xFFA42D2D),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Account deletion will be added soon.'),
              ));
            },
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingPill,
    this.titleColor,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailingPill;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: titleColor ?? AppColors.navy900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (trailingPill != null) ...[
              trailingPill!,
              const SizedBox(width: 6),
            ],
            Icon(Icons.chevron_right, size: 20, color: AppColors.textSubtle),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: fg,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: AppColors.border.withOpacity(0.45),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Security note
// ─────────────────────────────────────────────────────────────────

class _SecurityNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4F0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined,
              color: AppColors.teal600, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Datasolids uses Fernet column-level encryption at rest and TLS in transit.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.navy900,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.onRetry});
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.cloud_off_outlined, color: AppColors.textMuted, size: 32),
          const SizedBox(height: 10),
          Text("Couldn't load security settings",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.navy900,
              )),
          const SizedBox(height: 14),
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
