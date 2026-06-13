// Renders rich system notifications via flutter_local_notifications.
//
// We get a data-only FCM payload, then build the OS notification
// ourselves so it can have:
//   * A large square branded icon on the left
//   * BigText style — the body wraps to multiple lines when expanded
//   * "VIEW RESULTS" / "DISMISS" action buttons in the expanded view
//   * Deep-link target ("notification_id") attached to the tap intent
//
// Same code path for foreground / background / app-killed states.
// Background handler in push_service.dart calls into [showFromData].

import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Color;

import 'package:datasolids_mobile/features/notifications/data/dtos/notification.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


/// Notification channel id — must match the one MainActivity.kt creates
/// and the one the backend's FCM dispatcher targets. Don't change
/// without updating both sides.
const String _channelId = 'datasolids_default';
const String _channelName = 'Datasolids notifications';

/// Internal "action ids" the user can tap on the rich notification.
/// We round-trip these through the payload so the launcher intent
/// fires the right deep link.
const String actionView = 'view';
const String actionDismiss = 'dismiss';


class LocalNotificationsService {
  LocalNotificationsService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Stream of (notification_id, action_id) tuples for the UI / push
  /// service to subscribe to. Emits on TAP (action_id == 'view') and
  /// on action-button presses.
  static final StreamController<NotificationTapEvent> _tapStream =
      StreamController<NotificationTapEvent>.broadcast();

  static Stream<NotificationTapEvent> get tapStream => _tapStream.stream;

  /// Idempotent — safe to call from foreground bootstrap AND from the
  /// background isolate (which always boots fresh).
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    const androidInit = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundTap,
    );

    // Re-create the channel here too as belt-and-suspenders — the OS
    // ignores the call if the channel already exists with the same id.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'Lab results, sync updates, and security alerts.',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          ),
        );
  }

  /// Render a notification from an FCM data-only payload. Called both
  /// from foreground (push_service.onMessage) and the background
  /// isolate (top-level @pragma handler).
  static Future<void> showFromData(Map<String, dynamic> data) async {
    await initialize();

    final title = data['title']?.toString() ?? 'Datasolids';
    final body = data['body']?.toString() ?? '';
    final kindRaw = data['kind']?.toString() ?? 'generic';
    final notifId = data['notification_id']?.toString() ?? '';

    final kind = NotificationKind.parse(kindRaw);

    // Payload encoded as JSON — flutter_local_notifications hands this
    // back unchanged in the tap callback so we can deep-link.
    final payload = jsonEncode({
      'notification_id': notifId,
      'kind': kindRaw,
    });

    final androidDetails = AndroidNotificationDetails(
      _channelId, _channelName,
      channelDescription:
          'Lab results, sync updates, and security alerts.',
      importance: Importance.high,
      priority: Priority.high,
      // Brand teal — tints the small icon on the lock screen.
      color: const Color.fromARGB(0xFF, 0x31, 0x97, 0x95),
      // BigText so the body wraps to multiple lines in the expanded
      // view (matches the "142 new resources were added to your pod."
      // design state).
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Datasolids',
      ),
      ticker: title,
      actions: _actionsFor(kind),
      // Tag = notification_id so re-sends for the same logical event
      // replace the existing toast instead of stacking duplicates.
      tag: notifId.isEmpty ? null : notifId,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      // notification id (int) — derive from notification_id hash to
      // collide intentionally for the same logical event.
      notifId.isEmpty ? DateTime.now().millisecondsSinceEpoch.remainder(100000)
                      : notifId.hashCode.toUnsigned(31),
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  /// Action button definitions — labels vary slightly per kind so the
  /// CTA reads naturally for the user. The action id is what we get
  /// back in the tap callback.
  static List<AndroidNotificationAction> _actionsFor(
    NotificationKind kind,
  ) {
    final viewLabel = switch (kind) {
      NotificationKind.labResult => 'View results',
      NotificationKind.syncCompleted => 'Open my pod',
      NotificationKind.securitySignin => 'Review sessions',
      NotificationKind.grantAccessed => 'Who saw it',
      _ => 'View',
    };
    return [
      AndroidNotificationAction(
        actionView, viewLabel,
        showsUserInterface: true,
        cancelNotification: true,
      ),
      const AndroidNotificationAction(
        actionDismiss, 'Dismiss',
        cancelNotification: true,
      ),
    ];
  }

  // ─── Tap handlers ─────────────────────────────────────────────────

  /// Fires when the user taps the notification body, or one of the
  /// action buttons, while the app is in foreground OR background but
  /// still running. NOT called when the app was fully killed — see
  /// [getLaunchPayload] for that case.
  static void _onTap(NotificationResponse resp) {
    final actionId = resp.actionId ?? actionView;
    final payload = _decode(resp.payload);
    _tapStream.add(NotificationTapEvent(
      actionId: actionId,
      notificationId: payload['notification_id'] as String? ?? '',
      kind: payload['kind'] as String? ?? '',
    ));
  }

  /// Runs in the background isolate when the app is killed. Can't
  /// touch UI from here — just record the intent so the next foreground
  /// boot picks it up via [getLaunchPayload].
  @pragma('vm:entry-point')
  static void _onBackgroundTap(NotificationResponse resp) {
    // No-op: when the app is fully killed, the OS will relaunch it
    // and the cold-start handler in push_service.dart reads
    // `getNotificationAppLaunchDetails()` to figure out where to go.
  }

  /// Call once after the app boots to see if it was launched by a
  /// notification tap. Returns null when launched normally.
  static Future<NotificationTapEvent?> getLaunchPayload() async {
    await initialize();
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    final resp = details?.notificationResponse;
    final payload = _decode(resp?.payload);
    return NotificationTapEvent(
      actionId: resp?.actionId ?? actionView,
      notificationId: payload['notification_id'] as String? ?? '',
      kind: payload['kind'] as String? ?? '',
    );
  }

  static Map<String, dynamic> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return const {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }
}


/// Carrier used by the tap stream + cold-start launch payload — keeps
/// the push_service tap handler free of jsonDecode boilerplate.
class NotificationTapEvent {
  const NotificationTapEvent({
    required this.actionId,
    required this.notificationId,
    required this.kind,
  });
  final String actionId;          // 'view' | 'dismiss'
  final String notificationId;
  final String kind;
}
