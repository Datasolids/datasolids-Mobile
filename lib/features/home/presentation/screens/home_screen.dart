// Home dashboard. Matches the "Mobile: Home Dashboard" Figma references.
//
// Bound to GET /pods/me/summary/ via dashboardControllerProvider. Shows the
// empty/first-time state ("Your pod is ready" + Get Started checklist) when
// the pod has no connections and no resources, otherwise the populated Pod
// Status card + live Recent Activity feed.

import 'package:datasolids_mobile/core/auth/token_manager.dart';
import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:datasolids_mobile/features/home/data/dtos/dashboard_summary.dart';
import 'package:datasolids_mobile/features/home/presentation/controllers/dashboard_controller.dart';
import 'package:datasolids_mobile/features/home/presentation/widgets/profile_drawer.dart';
import 'package:datasolids_mobile/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:datasolids_mobile/features/pod/presentation/screens/my_pod_explorer_screen.dart';
import 'package:datasolids_mobile/features/profile/presentation/controllers/current_user_controller.dart';
import 'package:datasolids_mobile/features/profile/presentation/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Short relative-time label for activity rows, e.g. "2H AGO".
String _relativeTime(DateTime? t) {
  if (t == null) return '';
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'JUST NOW';
  if (d.inMinutes < 60) return '${d.inMinutes}M AGO';
  if (d.inHours < 24) return '${d.inHours}H AGO';
  if (d.inDays < 7) return '${d.inDays}D AGO';
  return '${(d.inDays / 7).floor()}W AGO';
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFAF7F2),
      endDrawer: const ProfileDrawer(),
      body: SafeArea(
        child: _buildBody(),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    switch (_tab) {
      case 0:
        return _HomeTab(
          onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(),
        );
      case 1:
        // My Pod Explorer — full category breakdown + recent documents.
        // Back arrow flips back to the Home tab (index 0).
        return MyPodExplorerTab(
          onBackToHome: () => setState(() => _tab = 0),
        );
      case 2:
        return const _PlaceholderTab(
          title: 'Grants',
          subtitle: 'Active and pending data-access grants.',
          icon: Icons.workspace_premium_outlined,
        );
      case 3:
        return _ProfileTab(
          onSignOut: () => ref.read(tokenManagerProvider).signOut(),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomNav() {
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
              _NavItem(
                icon: Icons.home_outlined,
                iconActive: Icons.home,
                label: 'HOME',
                selected: _tab == 0,
                onTap: () => setState(() => _tab = 0),
              ),
              _NavItem(
                icon: Icons.dataset_linked_outlined,
                iconActive: Icons.dataset_linked,
                label: 'MY POD',
                selected: _tab == 1,
                onTap: () => setState(() => _tab = 1),
              ),
              _NavItem(
                icon: Icons.shield_outlined,
                iconActive: Icons.shield,
                label: 'GRANTS',
                selected: _tab == 2,
                onTap: () => setState(() => _tab = 2),
              ),
              _NavItem(
                icon: Icons.person_outline,
                iconActive: Icons.person,
                label: 'PROFILE',
                selected: _tab == 3,
                onTap: () => setState(() => _tab = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Home tab — the main dashboard
// ─────────────────────────────────────────────────────────────────

class _HomeTab extends ConsumerWidget {
  const _HomeTab({required this.onMenuTap});
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);
    final summary = state.summary;

    return RefreshIndicator(
      color: AppColors.teal600,
      onRefresh: () =>
          ref.read(dashboardControllerProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(onMenuTap: onMenuTap),
            const SizedBox(height: 20),
            if (summary == null && state.isLoading)
              const _DashboardLoading()
            else if (summary == null)
              _DashboardError(
                onRetry: () =>
                    ref.read(dashboardControllerProvider.notifier).refresh(),
              )
            else if (summary.isEmpty)
              ..._emptyState()
            else
              ..._populatedState(summary),
          ],
        ),
      ),
    );
  }

  List<Widget> _emptyState() {
    return [
      const _EmptyPodCard(),
      const SizedBox(height: 26),
      const _SectionTitle('QUICK ACTIONS'),
      const SizedBox(height: 12),
      const _QuickActionsRow(),
      const SizedBox(height: 26),
      const _SectionTitle('GET STARTED'),
      const SizedBox(height: 12),
      const _GetStartedChecklist(),
    ];
  }

  List<Widget> _populatedState(DashboardSummary summary) {
    return [
      _PodStatusCard(summary: summary),
      const SizedBox(height: 26),
      const _SectionTitle('QUICK ACTIONS'),
      const SizedBox(height: 12),
      const _QuickActionsRow(),
      const SizedBox(height: 26),
      const _SectionTitleWithAction(
        title: 'RECENT ACTIVITY',
        action: 'See All',
      ),
      const SizedBox(height: 12),
      _ActivityFeed(items: summary.recentActivity),
    ];
  }
}

// ─────────────────────────────────────────────────────────────────
// Loading + error placeholders
// ─────────────────────────────────────────────────────────────────

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 168,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.navy900.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const CircularProgressIndicator(),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_outlined,
              color: AppColors.textMuted, size: 32),
          const SizedBox(height: 10),
          Text(
            "Couldn't load your pod",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.navy900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Check your connection and try again.',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: TextStyle(
                color: AppColors.teal600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Empty pod card — first-time state ("Your pod is ready")
// ─────────────────────────────────────────────────────────────────

class _EmptyPodCard extends StatelessWidget {
  const _EmptyPodCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A365D), Color(0xFF0F2742), Color(0xFF154360)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy900.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.14)),
            ),
            child: Icon(Icons.shield_outlined,
                color: AppColors.teal500, size: 26),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your pod is ready',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Encrypted and waiting for your first health record',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () => context.push('/connect'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_circle_outline,
                  size: 18, color: Colors.white),
              label: const Text(
                'Connect your first provider',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Get Started checklist (empty state)
// ─────────────────────────────────────────────────────────────────

class _GetStartedChecklist extends StatelessWidget {
  const _GetStartedChecklist();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _ChecklistRow(
          title: 'Connect a health provider',
          subtitle: 'Link your hospital or clinic portal',
        ),
        SizedBox(height: 10),
        _ChecklistRow(
          title: 'Upload your records (optional)',
          subtitle: 'Import historical PDFs or data files',
        ),
        SizedBox(height: 10),
        _ChecklistRow(
          title: 'Complete your profile',
          subtitle: 'Set up your security and preferences',
        ),
      ],
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.title,
    required this.subtitle,
    this.done = false,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final bool done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
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
            Icon(
              done ? Icons.check_circle : Icons.circle_outlined,
              color: done ? AppColors.teal600 : AppColors.border,
              size: 24,
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
                      color: AppColors.navy900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Header — avatar + welcome + bell + menu
// ─────────────────────────────────────────────────────────────────

/// Small red dot + count overlay for the bell icon. Hidden at zero.
/// 99+ collapses 3-digit counts so the pill doesn't blow up the layout.
class _UnreadBellBadge extends StatelessWidget {
  const _UnreadBellBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFE0524F),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFFAF7F2), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
    );
  }
}


class _Header extends ConsumerWidget {
  const _Header({required this.onMenuTap});
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserControllerProvider).user;
    final name = user?.fullName ?? 'Loading…';

    return Row(
      children: [
        UserAvatar(user: user, size: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WELCOME BACK',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppColors.textSubtle,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy900,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _CircleIconButton(
              icon: Icons.notifications_outlined,
              onTap: () => context.push('/notifications'),
            ),
            // Unread badge — anchored to the icon's top-right corner.
            Positioned(
              top: -2, right: -2,
              child: _UnreadBellBadge(
                count: ref.watch(unreadNotificationsCountProvider),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        _CircleIconButton(
          icon: Icons.menu,
          onTap: onMenuTap,
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withOpacity(0.6)),
        ),
        child: Icon(icon, color: AppColors.navy900, size: 20),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Pod status card — navy gradient
// ─────────────────────────────────────────────────────────────────

class _PodStatusCard extends StatelessWidget {
  const _PodStatusCard({required this.summary});
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final count = summary.activeConnections;
    final headline =
        summary.status.toLowerCase() == 'active' ? 'Encrypted & Active' : 'Encrypted';
    final badges = summary.sources.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A365D), Color(0xFF0F2742), Color(0xFF154360)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy900.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'POD STATUS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              Icon(
                Icons.verified_user_outlined,
                color: AppColors.teal500,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            headline,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),

          // Syncing pill.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.14),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timeline,
                  size: 16,
                  color: AppColors.teal500,
                ),
                const SizedBox(width: 8),
                Text(
                  '$count Clinical Source${count == 1 ? '' : 's'} Syncing',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Source initials avatars (from the active connections).
              Row(
                children: [
                  for (var i = 0; i < badges.length; i++)
                    _SourcePill(label: badges[i].badge, overlap: i > 0),
                ],
              ),
              GestureDetector(
                onTap: () {},
                child: Row(
                  children: [
                    Text(
                      'View Details',
                      style: TextStyle(
                        color: AppColors.teal500,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: AppColors.teal500,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourcePill extends StatelessWidget {
  const _SourcePill({required this.label, this.overlap = false});
  final String label;
  final bool overlap;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(overlap ? -8 : 0, 0),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.navy900, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.navy900,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Section titles
// ─────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        color: AppColors.textSubtle,
      ),
    );
  }
}

class _SectionTitleWithAction extends StatelessWidget {
  const _SectionTitleWithAction({required this.title, required this.action});
  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _SectionTitle(title),
        GestureDetector(
          onTap: () {},
          child: Text(
            action,
            style: TextStyle(
              color: AppColors.teal600,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Quick actions
// ─────────────────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.link_rounded,
            title: 'Connect EHR',
            subtitle: 'Epic, Cerner, Athena',
            onTap: () => context.push('/connect'),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: _QuickActionCard(
            icon: Icons.cloud_upload_outlined,
            title: 'Upload Files',
            subtitle: 'JSON, CSV, PDF',
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.teal500.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.teal600, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
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
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Activity feed
// ─────────────────────────────────────────────────────────────────

class _ActivityFeed extends StatelessWidget {
  const _ActivityFeed({required this.items});
  final List<DashboardActivity> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Promotional offer (marketing surface, not from the summary API).
        const _ActivityCard(
          icon: Icons.bolt,
          iconBg: Color(0x1A2A7B7B),
          iconColor: AppColors.teal600,
          title: 'Earn \$50.00',
          subtitle: 'Stanford Diabetes Research Study',
          rightLabel: 'NEW OFFER',
          highlight: true,
          showChevron: true,
        ),
        // Live activity from the backend (sync jobs + grants).
        for (final item in items) ...[
          const SizedBox(height: 10),
          _ActivityCard(
            icon: _iconFor(item.type),
            iconBg: _iconBgFor(item.type),
            iconColor: _iconColorFor(item.type),
            title: item.title,
            subtitle: item.subtitle,
            rightLabel: _relativeTime(item.timestamp),
          ),
        ],
      ],
    );
  }

  static IconData _iconFor(String type) {
    switch (type) {
      case 'sync':
        return Icons.check_circle_outline;
      case 'grant':
        return Icons.share_outlined;
      default:
        return Icons.bolt;
    }
  }

  static Color _iconBgFor(String type) {
    switch (type) {
      case 'sync':
        return const Color(0x1A2F855A);
      case 'grant':
        return const Color(0x1A2C5282);
      default:
        return const Color(0x1A2A7B7B);
    }
  }

  static Color _iconColorFor(String type) {
    switch (type) {
      case 'sync':
        return AppColors.green700;
      case 'grant':
        return AppColors.navy700;
      default:
        return AppColors.teal600;
    }
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.rightLabel,
    this.highlight = false,
    this.showChevron = false,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String rightLabel;
  final bool highlight;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? AppColors.teal500.withOpacity(0.5)
              : Colors.transparent,
          width: highlight ? 1.5 : 0,
        ),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
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
                    fontWeight: FontWeight.w700,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (highlight)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.teal500,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    rightLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                )
              else
                Text(
                  rightLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: AppColors.textSubtle,
                  ),
                ),
              if (showChevron) ...[
                const SizedBox(height: 6),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Bottom nav
// ─────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.iconActive,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData iconActive;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.teal600 : AppColors.textSubtle;
    return Expanded(
      child: InkWell(
        onTap: onTap,
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

// ─────────────────────────────────────────────────────────────────
// Stub tabs (My Pod / Grants)
// ─────────────────────────────────────────────────────────────────

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.teal500.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: AppColors.teal600, size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.navy900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.teal500.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'COMING SOON',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: AppColors.teal600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab({required this.onSignOut});
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserControllerProvider).user;
    final name = user?.fullName ?? 'Loading…';
    final email = user?.email ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: UserAvatar(user: user, size: 88, borderWidth: 3),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.navy900,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              email,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => context.push('/profile/personal'),
            icon: const Icon(Icons.person_outline, size: 18),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navy900,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            label: const Text(
              'Edit personal profile',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: onSignOut,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.red700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Sign out',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
