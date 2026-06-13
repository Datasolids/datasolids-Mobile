// Notification Settings — /notifications/settings
//
// Matches the design: cream background, single top-level "Push
// Notifications" master toggle, CATEGORIES section with three cards
// (Security/Health Data/Grant Activity), each with a push toggle plus
// an optional "Email me too" row, and a QUIET HOURS card with a master
// toggle and FROM / TO time pickers.

import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:datasolids_mobile/features/notifications/data/dtos/notification_preferences.dart';
import 'package:datasolids_mobile/features/notifications/presentation/controllers/notification_preferences_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationPreferencesControllerProvider);
    final ctrl = ref
        .read(notificationPreferencesControllerProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.navy900,
        leading: const BackButton(),
        title: Text(
          'Notification Settings',
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
        child: state.prefs == null && state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.prefs == null
                ? _ErrorBlock(onRetry: ctrl.load)
                : _Body(prefs: state.prefs!, ctrl: ctrl),
      ),
    );
  }
}


class _Body extends StatelessWidget {
  const _Body({required this.prefs, required this.ctrl});
  final NotificationPreferences prefs;
  final NotificationPreferencesController ctrl;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ───── Master toggle ──────────────────────────────────────
          _Card(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Push Notifications',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Allow Datasolids to send alerts',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: prefs.pushEnabled,
                  onChanged: ctrl.setPushEnabled,
                  activeTrackColor: AppColors.teal600,
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),
          const _SectionLabel('CATEGORIES'),
          const SizedBox(height: 8),

          // ───── Category: Security & Access ─────────────────────────
          _CategoryCard(
            icon: Icons.shield_outlined,
            iconColor: AppColors.navy700,
            iconBg: AppColors.navy700.withOpacity(0.10),
            title: 'Security & Access',
            subtitle: 'Logins, MFA, and new devices',
            enabled: prefs.securityPush,
            onChanged: ctrl.setSecurityPush,
            emailEnabled: prefs.securityEmail,
            onEmailChanged: ctrl.setSecurityEmail,
          ),
          const SizedBox(height: 12),

          // ───── Category: Health Data ───────────────────────────────
          _CategoryCard(
            icon: Icons.science_outlined,
            iconColor: AppColors.teal600,
            iconBg: AppColors.teal600.withOpacity(0.12),
            title: 'Health Data',
            subtitle: 'New results and record updates',
            enabled: prefs.healthDataPush,
            onChanged: ctrl.setHealthDataPush,
            emailEnabled: prefs.healthDataEmail,
            onEmailChanged: ctrl.setHealthDataEmail,
          ),
          const SizedBox(height: 12),

          // ───── Category: Grant Activity ────────────────────────────
          _CategoryCard(
            icon: Icons.share_outlined,
            iconColor: AppColors.navy700,
            iconBg: AppColors.navy700.withOpacity(0.10),
            title: 'Grant Activity',
            subtitle: 'When researchers view records',
            enabled: prefs.grantActivityPush,
            onChanged: ctrl.setGrantActivityPush,
            emailEnabled: prefs.grantActivityEmail,
            onEmailChanged: ctrl.setGrantActivityEmail,
          ),

          const SizedBox(height: 22),
          const _SectionLabel('QUIET HOURS'),
          const SizedBox(height: 8),

          // ───── Quiet Hours card ────────────────────────────────────
          _Card(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.bedtime_outlined,
                        size: 18, color: AppColors.navy700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Scheduled Pause',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy900,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: prefs.quietHoursEnabled,
                      onChanged: ctrl.setQuietHoursEnabled,
                      activeTrackColor: AppColors.teal600,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _TimeBlock(
                        label: 'FROM',
                        time: prefs.quietHoursFrom,
                        muted: !prefs.quietHoursEnabled,
                        onPick: (t) => ctrl.setQuietHoursFrom(t),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward,
                          size: 18,
                          color: prefs.quietHoursEnabled
                              ? AppColors.navy700
                              : AppColors.textSubtle),
                    ),
                    Expanded(
                      child: _TimeBlock(
                        label: 'TO',
                        time: prefs.quietHoursTo,
                        muted: !prefs.quietHoursEnabled,
                        onPick: (t) => ctrl.setQuietHoursTo(t),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Pause everything except security alerts during these hours.',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textMuted,
                    height: 1.4,
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
// Reusable pieces
// ─────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding});
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onChanged,
    required this.emailEnabled,
    required this.onEmailChanged,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final bool emailEnabled;
  final ValueChanged<bool> onEmailChanged;

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: iconColor, size: 20),
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
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy900,
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
              Switch.adaptive(
                value: enabled,
                onChanged: onChanged,
                activeTrackColor: AppColors.teal600,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Divider(height: 14, color: AppColors.border.withOpacity(0.4)),
          // Email companion row
          Row(
            children: [
              Expanded(
                child: Text(
                  'Email me too',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: enabled
                        ? AppColors.navy900
                        : AppColors.textMuted,
                  ),
                ),
              ),
              Switch.adaptive(
                value: emailEnabled,
                onChanged: enabled ? onEmailChanged : null,
                activeTrackColor: AppColors.teal600,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeBlock extends StatelessWidget {
  const _TimeBlock({
    required this.label,
    required this.time,
    required this.muted,
    required this.onPick,
  });
  final String label;
  final TimeOfDay time;
  final bool muted;
  final ValueChanged<TimeOfDay> onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: muted
          ? null
          : () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: time,
                builder: (ctx, child) => MediaQuery(
                  data: MediaQuery.of(ctx)
                      .copyWith(alwaysUse24HourFormat: false),
                  child: child!,
                ),
              );
              if (picked != null) onPick(picked);
            },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDisplay(time),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: muted ? AppColors.textMuted : AppColors.navy900,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDisplay(TimeOfDay t) {
    final h12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h12:$m $ampm';
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.onRetry});
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined,
              size: 32, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text("Couldn't load settings",
              style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: AppColors.navy900,
              )),
          TextButton(
            onPressed: () => onRetry(),
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
