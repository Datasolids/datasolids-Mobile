// State + actions for the Notification Settings screen.
//
// Loads prefs on creation, exposes optimistic toggle/save mutations so
// the UI flips instantly and rolls back if the API call fails. The
// screen never sees Future<…> — it reads `state.prefs` directly and
// calls action methods on the notifier.

import 'dart:async';

import 'package:datasolids_mobile/features/notifications/data/dtos/notification_preferences.dart';
import 'package:datasolids_mobile/features/notifications/data/notifications_api.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';


class NotificationPreferencesState {
  const NotificationPreferencesState({
    this.prefs,
    this.isLoading = false,
    this.errorMessage,
  });

  final NotificationPreferences? prefs;
  final bool isLoading;
  final String? errorMessage;

  NotificationPreferencesState copyWith({
    NotificationPreferences? prefs,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) =>
      NotificationPreferencesState(
        prefs: prefs ?? this.prefs,
        isLoading: isLoading ?? this.isLoading,
        errorMessage:
            clearError ? null : (errorMessage ?? this.errorMessage),
      );
}


class NotificationPreferencesController
    extends StateNotifier<NotificationPreferencesState> {
  NotificationPreferencesController(this._ref)
      : super(const NotificationPreferencesState()) {
    unawaited(load());
  }
  final Ref _ref;

  NotificationsApi get _api => _ref.read(notificationsApiProvider);

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final prefs = await _api.getPreferences();
      state = state.copyWith(prefs: prefs, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false, errorMessage: e.toString(),
      );
    }
  }

  // Helper that applies a transform optimistically, then patches the
  // backend with only the delta. Rolls back on failure.
  Future<void> _apply(
    NotificationPreferences Function(NotificationPreferences) transform,
  ) async {
    final before = state.prefs;
    if (before == null) return;
    final after = transform(before);
    final delta = after.diffJson(before);
    if (delta.isEmpty) return;
    state = state.copyWith(prefs: after);
    try {
      final fresh = await _api.updatePreferences(delta);
      state = state.copyWith(prefs: fresh);
    } catch (e) {
      // rollback
      state = state.copyWith(
        prefs: before, errorMessage: 'Could not save: $e',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Public mutation API — one method per toggle in the design.
  // ─────────────────────────────────────────────────────────────────

  Future<void> setPushEnabled(bool v) =>
      _apply((p) => p.copyWith(pushEnabled: v));

  Future<void> setSecurityPush(bool v) =>
      _apply((p) => p.copyWith(securityPush: v));
  Future<void> setHealthDataPush(bool v) =>
      _apply((p) => p.copyWith(healthDataPush: v));
  Future<void> setGrantActivityPush(bool v) =>
      _apply((p) => p.copyWith(grantActivityPush: v));

  Future<void> setSecurityEmail(bool v) =>
      _apply((p) => p.copyWith(securityEmail: v));
  Future<void> setHealthDataEmail(bool v) =>
      _apply((p) => p.copyWith(healthDataEmail: v));
  Future<void> setGrantActivityEmail(bool v) =>
      _apply((p) => p.copyWith(grantActivityEmail: v));

  Future<void> setQuietHoursEnabled(bool v) =>
      _apply((p) => p.copyWith(quietHoursEnabled: v));
  Future<void> setQuietHoursFrom(TimeOfDay v) =>
      _apply((p) => p.copyWith(quietHoursFrom: v));
  Future<void> setQuietHoursTo(TimeOfDay v) =>
      _apply((p) => p.copyWith(quietHoursTo: v));
}


final notificationPreferencesControllerProvider = StateNotifierProvider<
    NotificationPreferencesController,
    NotificationPreferencesState>((ref) {
  return NotificationPreferencesController(ref);
});
