// Notifications state + actions.
//
// Two state holders:
//   1. notificationsFeedControllerProvider — drives the list screen.
//      Holds the list, the unread count, and a loading / error state.
//      Exposes refresh(), markRead, markUnread, archive, markAllRead so
//      the list and detail screens can mutate without re-fetching.
//   2. notificationDetailProvider — FutureProvider.family<id> the
//      detail screen reads, kept thin so the detail screen reuses the
//      same NotificationItem shape.
//
// We deliberately keep state on the StateNotifier (not in Riverpod's
// AsyncValue) so the screen can show the cached list while a
// background refresh runs.

import 'dart:async';

import 'package:datasolids_mobile/features/notifications/data/dtos/notification.dart';
import 'package:datasolids_mobile/features/notifications/data/notifications_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class NotificationsFeedState {
  const NotificationsFeedState({
    this.items = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<NotificationItem> items;
  final int unreadCount;
  final bool isLoading;
  final String? errorMessage;

  NotificationsFeedState copyWith({
    List<NotificationItem>? items,
    int? unreadCount,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) =>
      NotificationsFeedState(
        items: items ?? this.items,
        unreadCount: unreadCount ?? this.unreadCount,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}


class NotificationsFeedController
    extends StateNotifier<NotificationsFeedState> {
  NotificationsFeedController(this._ref)
      : super(const NotificationsFeedState()) {
    unawaited(refresh());
  }
  final Ref _ref;

  NotificationsApi get _api => _ref.read(notificationsApiProvider);

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final feed = await _api.list();
      state = NotificationsFeedState(
        items: feed.results,
        unreadCount: feed.unreadCount,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> markRead(String id) async {
    // Optimistic: flip locally first, then sync. Rollback on failure.
    final before = state.items;
    final updated = before.map((n) {
      if (n.id != id || n.isRead) return n;
      return NotificationItem(
        id: n.id, kind: n.kind, title: n.title, body: n.body,
        data: n.data, createdAt: n.createdAt,
        isRead: true, readAt: DateTime.now(),
        isArchived: n.isArchived, archivedAt: n.archivedAt,
      );
    }).toList();
    state = state.copyWith(
      items: updated,
      unreadCount: state.unreadCount > 0 && _wasUnread(before, id)
          ? state.unreadCount - 1
          : state.unreadCount,
    );
    try {
      await _api.markRead(id);
    } catch (_) {
      state = state.copyWith(items: before);
    }
  }

  Future<void> markUnread(String id) async {
    final before = state.items;
    final updated = before.map((n) {
      if (n.id != id || !n.isRead) return n;
      return NotificationItem(
        id: n.id, kind: n.kind, title: n.title, body: n.body,
        data: n.data, createdAt: n.createdAt,
        isRead: false, readAt: null,
        isArchived: n.isArchived, archivedAt: n.archivedAt,
      );
    }).toList();
    state = state.copyWith(
      items: updated,
      unreadCount: state.unreadCount + 1,
    );
    try {
      await _api.markUnread(id);
    } catch (_) {
      state = state.copyWith(items: before);
    }
  }

  Future<void> archive(String id) async {
    final before = state.items;
    final wasUnread = _wasUnread(before, id);
    final updated = before.where((n) => n.id != id).toList();
    state = state.copyWith(
      items: updated,
      unreadCount: wasUnread
          ? (state.unreadCount > 0 ? state.unreadCount - 1 : 0)
          : state.unreadCount,
    );
    try {
      await _api.archive(id);
    } catch (_) {
      state = state.copyWith(items: before);
    }
  }

  Future<void> markAllRead() async {
    final before = state.items;
    final updated = before.map((n) {
      if (n.isRead) return n;
      return NotificationItem(
        id: n.id, kind: n.kind, title: n.title, body: n.body,
        data: n.data, createdAt: n.createdAt,
        isRead: true, readAt: DateTime.now(),
        isArchived: n.isArchived, archivedAt: n.archivedAt,
      );
    }).toList();
    state = state.copyWith(items: updated, unreadCount: 0);
    try {
      await _api.markAllRead();
    } catch (_) {
      state = state.copyWith(items: before);
      unawaited(refresh());
    }
  }

  static bool _wasUnread(List<NotificationItem> items, String id) {
    final i = items.indexWhere((n) => n.id == id);
    return i >= 0 && !items[i].isRead;
  }
}


final notificationsFeedControllerProvider = StateNotifierProvider<
    NotificationsFeedController, NotificationsFeedState>((ref) {
  return NotificationsFeedController(ref);
});


/// Bell-badge count for the home header. Reads from the feed controller
/// so it updates the instant the user taps "Mark all read".
final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsFeedControllerProvider).unreadCount;
});


/// Single-notification detail. We try the cached list first so opening
/// a card from the list doesn't burn an extra HTTP round-trip.
final notificationDetailProvider =
    FutureProvider.family<NotificationItem, String>((ref, id) async {
  final cached = ref
      .read(notificationsFeedControllerProvider)
      .items
      .where((n) => n.id == id)
      .toList();
  if (cached.isNotEmpty) return cached.first;
  return ref.read(notificationsApiProvider).detail(id);
});
