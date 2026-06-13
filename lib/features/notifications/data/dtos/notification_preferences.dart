// Notification preferences — backs the /notifications/settings screen.
// One document per user; backend auto-creates defaults on first GET.

import 'package:flutter/material.dart' show TimeOfDay;


class NotificationPreferences {
  const NotificationPreferences({
    required this.pushEnabled,
    required this.securityPush,
    required this.healthDataPush,
    required this.grantActivityPush,
    required this.securityEmail,
    required this.healthDataEmail,
    required this.grantActivityEmail,
    required this.quietHoursEnabled,
    required this.quietHoursFrom,
    required this.quietHoursTo,
  });

  // Master switch.
  final bool pushEnabled;

  // Per-category push.
  final bool securityPush;
  final bool healthDataPush;
  final bool grantActivityPush;

  // Per-category email companion.
  final bool securityEmail;
  final bool healthDataEmail;
  final bool grantActivityEmail;

  // Quiet hours window (24-hr time, local).
  final bool quietHoursEnabled;
  final TimeOfDay quietHoursFrom;
  final TimeOfDay quietHoursTo;

  // copyWith for optimistic UI updates.
  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? securityPush,
    bool? healthDataPush,
    bool? grantActivityPush,
    bool? securityEmail,
    bool? healthDataEmail,
    bool? grantActivityEmail,
    bool? quietHoursEnabled,
    TimeOfDay? quietHoursFrom,
    TimeOfDay? quietHoursTo,
  }) => NotificationPreferences(
        pushEnabled: pushEnabled ?? this.pushEnabled,
        securityPush: securityPush ?? this.securityPush,
        healthDataPush: healthDataPush ?? this.healthDataPush,
        grantActivityPush: grantActivityPush ?? this.grantActivityPush,
        securityEmail: securityEmail ?? this.securityEmail,
        healthDataEmail: healthDataEmail ?? this.healthDataEmail,
        grantActivityEmail: grantActivityEmail ?? this.grantActivityEmail,
        quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
        quietHoursFrom: quietHoursFrom ?? this.quietHoursFrom,
        quietHoursTo: quietHoursTo ?? this.quietHoursTo,
      );

  factory NotificationPreferences.fromJson(Map<String, dynamic> j) {
    return NotificationPreferences(
      pushEnabled: j['push_enabled'] as bool? ?? true,
      securityPush: j['security_push'] as bool? ?? true,
      healthDataPush: j['health_data_push'] as bool? ?? true,
      grantActivityPush: j['grant_activity_push'] as bool? ?? true,
      securityEmail: j['security_email'] as bool? ?? false,
      healthDataEmail: j['health_data_email'] as bool? ?? false,
      grantActivityEmail: j['grant_activity_email'] as bool? ?? false,
      quietHoursEnabled: j['quiet_hours_enabled'] as bool? ?? false,
      quietHoursFrom: _parseTime(j['quiet_hours_from']) ??
          const TimeOfDay(hour: 22, minute: 0),
      quietHoursTo: _parseTime(j['quiet_hours_to']) ??
          const TimeOfDay(hour: 7, minute: 0),
    );
  }

  /// Partial-update payload — only include keys that changed so the
  /// PATCH stays small. Pass a fresh prefs object holding the desired
  /// values; we diff against [previous] and emit only the deltas.
  Map<String, dynamic> diffJson(NotificationPreferences previous) {
    final out = <String, dynamic>{};
    if (pushEnabled != previous.pushEnabled) {
      out['push_enabled'] = pushEnabled;
    }
    if (securityPush != previous.securityPush) {
      out['security_push'] = securityPush;
    }
    if (healthDataPush != previous.healthDataPush) {
      out['health_data_push'] = healthDataPush;
    }
    if (grantActivityPush != previous.grantActivityPush) {
      out['grant_activity_push'] = grantActivityPush;
    }
    if (securityEmail != previous.securityEmail) {
      out['security_email'] = securityEmail;
    }
    if (healthDataEmail != previous.healthDataEmail) {
      out['health_data_email'] = healthDataEmail;
    }
    if (grantActivityEmail != previous.grantActivityEmail) {
      out['grant_activity_email'] = grantActivityEmail;
    }
    if (quietHoursEnabled != previous.quietHoursEnabled) {
      out['quiet_hours_enabled'] = quietHoursEnabled;
    }
    if (quietHoursFrom != previous.quietHoursFrom) {
      out['quiet_hours_from'] = _formatTime(quietHoursFrom);
    }
    if (quietHoursTo != previous.quietHoursTo) {
      out['quiet_hours_to'] = _formatTime(quietHoursTo);
    }
    return out;
  }
}


TimeOfDay? _parseTime(dynamic raw) {
  if (raw == null) return null;
  final s = raw.toString();
  // Backend serializes as "HH:MM:SS" or "HH:MM".
  final parts = s.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts[1]) ?? 0;
  return TimeOfDay(hour: h, minute: m);
}

String _formatTime(TimeOfDay t) {
  String pad(int v) => v.toString().padLeft(2, '0');
  return '${pad(t.hour)}:${pad(t.minute)}:00';
}
