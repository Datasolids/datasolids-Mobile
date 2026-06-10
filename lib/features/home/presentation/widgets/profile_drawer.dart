// Right-side navigation drawer. Opened from the hamburger button on the
// home dashboard. Matches the "Mobile: Navigation" V2 Figma reference.

import 'package:datasolids_mobile/core/auth/token_manager.dart';
import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:datasolids_mobile/features/profile/presentation/controllers/current_user_controller.dart';
import 'package:datasolids_mobile/features/profile/presentation/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileDrawer extends ConsumerStatefulWidget {
  const ProfileDrawer({super.key});

  @override
  ConsumerState<ProfileDrawer> createState() => _ProfileDrawerState();
}

class _ProfileDrawerState extends ConsumerState<ProfileDrawer> {
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserControllerProvider).user;
    final name = user?.fullName ?? 'Loading…';
    final role = user?.roleLabel ?? 'Patient Account';

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.86,
      backgroundColor: const Color(0xFF0F2742),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F2742), Color(0xFF1A365D), Color(0xFF0F2742)],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Header: avatar + name + close ─────────────
                Row(
                  children: [
                    UserAvatar(user: user, size: 52),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            role,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkResponse(
                      onTap: () => Navigator.of(context).pop(),
                      radius: 22,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.white.withOpacity(0.85),
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                _SectionLabel('ACCOUNT & SECURITY'),
                const SizedBox(height: 12),
                _DrawerItem(
                  icon: Icons.person_outline,
                  label: 'Personal Profile',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/profile/personal');
                  },
                ),
                const SizedBox(height: 10),
                _DrawerItem(
                  icon: Icons.lock_outline,
                  label: 'Security & MFA',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/security');
                  },
                ),
                const SizedBox(height: 10),
                _DrawerItem(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  badge: '2',
                  onTap: () {
                    Navigator.of(context).pop();
                    _showComingSoon(context);
                  },
                ),
                const SizedBox(height: 10),
                _DrawerItem(
                  icon: Icons.bolt,
                  iconColor: AppColors.amber500,
                  label: 'Monetization Hub',
                  trailing: const Text(
                    '\$1,240',
                    style: TextStyle(
                      color: AppColors.amber500,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showComingSoon(context);
                  },
                ),

                const SizedBox(height: 28),
                _SectionLabel('APP SETTINGS'),
                const SizedBox(height: 12),
                _DrawerItem(
                  icon: Icons.language,
                  label: 'Language',
                  trailing: Text(
                    'English',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  showArrow: false,
                  onTap: () => _showComingSoon(context),
                ),
                const SizedBox(height: 10),
                _DrawerItem(
                  icon: Icons.dark_mode_outlined,
                  label: 'Dark Mode',
                  trailing: Switch(
                    value: _darkMode,
                    onChanged: (v) => setState(() => _darkMode = v),
                    activeColor: Colors.white,
                    activeTrackColor: AppColors.teal500,
                    inactiveTrackColor: Colors.white.withOpacity(0.15),
                    inactiveThumbColor: Colors.white.withOpacity(0.6),
                  ),
                  showArrow: false,
                  onTap: () => setState(() => _darkMode = !_darkMode),
                ),

                const Spacer(),

                // ─── Sign out ─────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await ref.read(tokenManagerProvider).signOut();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.logout,
                            color: AppColors.navy900,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Sign Out',
                            style: TextStyle(
                              color: AppColors.navy900,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _FooterLink(label: 'PRIVACY', onTap: () {}),
                    _FooterLink(label: 'TERMS', onTap: () {}),
                    _FooterLink(label: 'SUPPORT', onTap: () {}),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Version 2.4.0 (Build 892)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Coming soon.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy900,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.45),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.8,
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.badge,
    this.trailing,
    this.showArrow = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final String? badge;
  final Widget? trailing;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                color: iconColor ?? AppColors.teal500,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (badge != null) ...[
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.teal500,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              if (trailing != null) trailing!,
              if (showArrow) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward,
                  color: Colors.white.withOpacity(0.5),
                  size: 16,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.55),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}
