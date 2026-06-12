// Foreground/background push notification service.
//
// Owns the firebase_messaging lifecycle:
//   1. Initializes Firebase Core (no-op if not yet configured)
//   2. Requests notification permission on iOS / Android 13+
//   3. Fetches the current FCM token and pushes it to the backend
//   4. Listens for token rotations (onTokenRefresh) and re-registers
//   5. Wires foreground / background / tap message handlers
//
// **Safe to call without Firebase being configured.** If
// google-services.json (Android) or GoogleService-Info.plist (iOS) is
// missing, init throws; we swallow it and log. The in-app feed keeps
// working — only push goes silent.
//
// Hot-restart caveat: keep this file at a top-level entrypoint
// reachable by the AOT compiler so the background isolate's static
// handler is found.

import 'dart:async';
import 'dart:io' show Platform;

import 'package:datasolids_mobile/app/router.dart';
import 'package:datasolids_mobile/core/device/device_id.dart';
import 'package:datasolids_mobile/core/logging/logger.dart';
import 'package:datasolids_mobile/features/notifications/data/notifications_api.dart';
import 'package:datasolids_mobile/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


/// Background handler — Firebase requires this be a top-level function
/// (it runs in a separate isolate). We can't touch Riverpod or UI from
/// here; the OS itself shows the notification. We CAN call
/// FlutterAppBadger because it talks to the platform launcher
/// directly without needing the app to be running.
@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  appLogger.i('Push received in background: ${message.messageId}');
  await _applyBadgeFromMessage(message);
}

/// Reads `unread_count` from the FCM data payload and writes it to the
/// OS launcher badge. Safe to call from any isolate — flutter_app_badger
/// is platform-channel-only, no Riverpod dependency.
Future<void> _applyBadgeFromMessage(RemoteMessage msg) async {
  try {
    final raw = msg.data['unread_count']?.toString() ?? '';
    final count = int.tryParse(raw) ?? 0;
    final supported = await FlutterAppBadger.isAppBadgeSupported();
    if (!supported) return;
    if (count <= 0) {
      await FlutterAppBadger.removeBadge();
    } else {
      await FlutterAppBadger.updateBadgeCount(count);
    }
  } catch (e) {
    // Best-effort — never crash a push handler over a badge.
    appLogger.w('Could not update launcher badge: $e');
  }
}


class PushNotificationService {
  PushNotificationService(this._ref);
  final Ref _ref;

  bool _initialized = false;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;

  /// Call once on app start (post-authentication). Idempotent.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // initializeApp throws if Firebase isn't configured for this
      // platform (missing google-services.json / Info.plist). Catch and
      // log — push silently disabled, rest of the app keeps running.
      await Firebase.initializeApp();
    } catch (e) {
      appLogger.w('Firebase not configured — push disabled: $e');
      return;
    }

    final messaging = FirebaseMessaging.instance;

    // Permission. On Android < 13 this returns authorized without
    // prompting; on iOS and Android 13+ it shows the OS sheet.
    final settings = await messaging.requestPermission(
      alert: true, badge: true, sound: true, provisional: false,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      appLogger.i('Push permission denied');
    }

    FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);
    _foregroundSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);

    // Cold-launch from a notification tap.
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      // Defer the route push until the router is mounted.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _onMessageOpened(initial),
      );
    }

    // Initial token + future refreshes.
    await _registerCurrentToken();
    _tokenRefreshSub = messaging.onTokenRefresh.listen((token) async {
      await _register(token);
    });
  }

  /// Re-register after login (so a user who reinstalls / changes
  /// account on the same phone overwrites the previous owner's row).
  Future<void> reregisterAfterLogin() async {
    if (!_initialized) return;
    await _registerCurrentToken();
  }

  Future<void> _registerCurrentToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await _register(token);
    } catch (e) {
      appLogger.w('Could not fetch FCM token: $e');
    }
  }

  Future<void> _register(String token) async {
    try {
      final deviceId = _ref.read(deviceIdManagerProvider).value;
      final platform = Platform.isIOS ? 'ios'
                     : Platform.isAndroid ? 'android'
                     : 'web';
      await _ref.read(notificationsApiProvider).registerDeviceToken(
        deviceId: deviceId,
        platform: platform,
        token: token,
      );
      appLogger.i('Registered FCM token (${token.substring(0, 8)}…)');
    } catch (e) {
      appLogger.w('Failed to register FCM token with backend: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Foreground + tap handling
  // ─────────────────────────────────────────────────────────────────

  void _onForegroundMessage(RemoteMessage msg) {
    // Bump the feed so the new notification shows in the list right
    // away and the in-app unread badge ticks up.
    unawaited(
      _ref.read(notificationsFeedControllerProvider.notifier).refresh(),
    );
    // Repaint the launcher icon badge — handler runs in the main
    // isolate so the foreground app and the launcher stay in sync.
    unawaited(_applyBadgeFromMessage(msg));
  }

  void _onMessageOpened(RemoteMessage msg) {
    // The Celery dispatcher stamps notification_id into the data
    // payload so we can deep-link straight to the detail screen.
    // Routing through the GoRouter directly (rather than a navigator
    // key) works on cold start because routerProvider is a singleton.
    final id = msg.data['notification_id']?.toString() ?? '';
    try {
      final router = _ref.read(routerProvider);
      if (id.isNotEmpty) {
        router.go('/notifications/$id');
      } else {
        router.go('/notifications');
      }
    } catch (e) {
      appLogger.w('Push route failed: $e');
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
    _tokenRefreshSub = null;
    _foregroundSub = null;
    _openedSub = null;
    _initialized = false;
  }
}


final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) {
  final svc = PushNotificationService(ref);
  ref.onDispose(svc.dispose);
  return svc;
});
