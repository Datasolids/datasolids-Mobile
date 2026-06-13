// In-app banner overlay service.
//
// Public API is exactly one method: ``show(...)``. The service handles:
//   • Mounting an OverlayEntry above whatever screen is active
//   • Slide-down + fade-in animation on enter, slide-up on exit
//   • Stacking multiple banners vertically with a small gap
//   • Auto-dismissal after a configurable duration (default 6 sec)
//   • Manual dismiss via the X button
//   • Tap-through that closes the banner first, THEN calls onTap so
//     the deep link doesn't trigger from a half-dismissed widget
//
// Sub-second end-to-end latency. The foreground FCM handler in
// push_service.dart calls into this directly; the banner appears in
// the same frame the FirebaseMessaging.onMessage stream emits.

import 'dart:async';

import 'package:datasolids_mobile/features/notifications/data/dtos/notification.dart';
import 'package:datasolids_mobile/features/notifications/presentation/widgets/in_app_banner.dart';
import 'package:flutter/material.dart';


class InAppBannerService {
  InAppBannerService._();

  /// Live banners in the order they were shown. We stack them top-down
  /// so the newest is on top; dismissing any one collapses the stack.
  static final List<_BannerHandle> _live = [];

  /// Display a banner derived from a [NotificationItem]. The visual
  /// (icon, color) is picked from [NotificationKind]; the title/body
  /// come from the notification payload.
  static void showForNotification(
    BuildContext context, {
    required NotificationItem notification,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 6),
  }) {
    final style = _styleFor(notification.kind);
    show(
      context,
      title: notification.title,
      body: notification.body,
      icon: style.icon,
      iconColor: style.color,
      onTap: onTap,
      duration: duration,
    );
  }

  /// Direct entry point — pass title/body/icon/color explicitly when
  /// you want a banner that isn't backed by a NotificationItem.
  static void show(
    BuildContext context, {
    required String title,
    required String body,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 6),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    late OverlayEntry entry;
    final handle = _BannerHandle();

    entry = OverlayEntry(builder: (ctx) {
      return _BannerSlot(
        handle: handle,
        title: title,
        body: body,
        icon: icon,
        iconColor: iconColor,
        duration: duration,
        onTap: onTap,
        onClosed: () {
          if (entry.mounted) entry.remove();
          _live.remove(handle);
          // Force the remaining banners to re-layout to their new
          // positions in the stack.
          for (final h in _live) {
            h.notifyRepositionListeners();
          }
        },
        positionInStack: () => _live.indexOf(handle),
      );
    });

    handle.entry = entry;
    _live.add(handle);
    overlay.insert(entry);
  }

  // ─────────────────────────────────────────────────────────────────
  // Icon + color for each notification kind. Matches the in-list and
  // detail-screen visuals so the banner blends with the rest of the
  // notification UI.
  // ─────────────────────────────────────────────────────────────────

  static _BannerStyle _styleFor(NotificationKind k) {
    switch (k) {
      case NotificationKind.securitySignin:
        return const _BannerStyle(
          icon: Icons.shield_outlined,
          color: Color(0xFF1A365D),  // navy900
        );
      case NotificationKind.syncCompleted:
        return const _BannerStyle(
          icon: Icons.check_circle_outline,
          color: Color(0xFF1A365D),
        );
      case NotificationKind.labResult:
        return const _BannerStyle(
          icon: Icons.science_outlined,
          color: Color(0xFF319795),  // teal600
        );
      case NotificationKind.grantAccessed:
        return const _BannerStyle(
          icon: Icons.share_outlined,
          color: Color(0xFF1A365D),
        );
      case NotificationKind.researchOpportunity:
        return const _BannerStyle(
          icon: Icons.info_outline,
          color: Color(0xFF7C5CFC),  // soft violet
        );
      case NotificationKind.appUpdate:
        return const _BannerStyle(
          icon: Icons.settings_outlined,
          color: Color(0xFF1A365D),
        );
      case NotificationKind.generic:
        return const _BannerStyle(
          icon: Icons.notifications_outlined,
          color: Color(0xFF1A365D),
        );
    }
  }
}


class _BannerStyle {
  const _BannerStyle({required this.icon, required this.color});
  final IconData icon;
  final Color color;
}


/// Mutable lifecycle state shared between the OverlayEntry builder and
/// the service. Wrapped in a class so the builder closure can capture
/// a stable reference.
class _BannerHandle {
  OverlayEntry? entry;

  final List<VoidCallback> _repositionListeners = [];

  void addRepositionListener(VoidCallback cb) {
    _repositionListeners.add(cb);
  }
  void removeRepositionListener(VoidCallback cb) {
    _repositionListeners.remove(cb);
  }
  void notifyRepositionListeners() {
    for (final cb in List.of(_repositionListeners)) {
      cb();
    }
  }
}


/// The actual widget rendered into the Overlay. Owns its own animation
/// controller via [SingleTickerProviderStateMixin] so vsync is always
/// valid regardless of where the Overlay is anchored.
class _BannerSlot extends StatefulWidget {
  const _BannerSlot({
    required this.handle,
    required this.title,
    required this.body,
    required this.icon,
    required this.iconColor,
    required this.duration,
    required this.onClosed,
    required this.positionInStack,
    this.onTap,
  });

  final _BannerHandle handle;
  final String title;
  final String body;
  final IconData icon;
  final Color iconColor;
  final Duration duration;
  final VoidCallback? onTap;
  final VoidCallback onClosed;
  final int Function() positionInStack;

  @override
  State<_BannerSlot> createState() => _BannerSlotState();
}

class _BannerSlotState extends State<_BannerSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _autoTimer;
  late int _position = widget.positionInStack();
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 180),
    );
    widget.handle.addRepositionListener(_refreshPosition);
    _controller.forward();
    _autoTimer = Timer(widget.duration, _dismiss);
  }

  void _refreshPosition() {
    if (!mounted) return;
    final next = widget.positionInStack();
    if (next != _position) setState(() => _position = next);
  }

  Future<void> _dismiss() async {
    if (_dismissed || !mounted) return;
    _dismissed = true;
    _autoTimer?.cancel();
    try {
      await _controller.reverse();
    } catch (_) {
      // controller may already be disposed — ignore
    }
    if (mounted) widget.onClosed();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    widget.handle.removeRepositionListener(_refreshPosition);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset =
        MediaQuery.of(context).viewPadding.top + 8 + _position * 84;
    return Positioned(
      top: topInset,
      left: 12,
      right: 12,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (ctx, child) {
          final t = _controller.value;
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, (1 - t) * -24),
              child: child,
            ),
          );
        },
        child: InAppBanner(
          title: widget.title,
          body: widget.body,
          icon: widget.icon,
          iconColor: widget.iconColor,
          onTap: () async {
            await _dismiss();
            widget.onTap?.call();
          },
          onDismiss: _dismiss,
        ),
      ),
    );
  }
}
