// Thin HTTP wrapper over the notifications surface. Mirrors the shape
// of features/security/data/security_api.dart so feature code consumes
// a typed Future instead of touching Dio directly.

import 'package:datasolids_mobile/core/network/dio_client.dart';
import 'package:datasolids_mobile/features/notifications/data/dtos/notification.dart';
import 'package:datasolids_mobile/features/notifications/data/dtos/notification_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class NotificationsApi {
  NotificationsApi(this._dio);
  final Dio _dio;

  Future<NotificationFeed> list({
    int page = 1,
    int pageSize = 30,
    bool includeArchived = false,
    String? kind,
  }) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/notifications/',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (includeArchived) 'include_archived': 'true',
        if (kind != null && kind.isNotEmpty) 'kind': kind,
      },
    );
    return NotificationFeed.fromJson(resp.data ?? const {});
  }

  Future<NotificationItem> detail(String id) async {
    final resp = await _dio.get<Map<String, dynamic>>('/notifications/$id/');
    return NotificationItem.fromJson(resp.data ?? const {});
  }

  Future<NotificationItem> markRead(String id) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/notifications/$id/read/',
    );
    return NotificationItem.fromJson(resp.data ?? const {});
  }

  Future<NotificationItem> markUnread(String id) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/notifications/$id/unread/',
    );
    return NotificationItem.fromJson(resp.data ?? const {});
  }

  Future<NotificationItem> archive(String id) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/notifications/$id/archive/',
    );
    return NotificationItem.fromJson(resp.data ?? const {});
  }

  Future<int> markAllRead() async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/notifications/mark-all-read/',
    );
    return (resp.data?['marked_read'] as num?)?.toInt() ?? 0;
  }

  /// Register an FCM/APNs token with the backend. Called after the
  /// user grants notification permission AND whenever firebase_messaging
  /// fires onTokenRefresh.
  Future<void> registerDeviceToken({
    required String deviceId,
    required String platform,  // 'ios' | 'android' | 'web'
    required String token,
  }) async {
    await _dio.post<void>(
      '/notifications/devices/register/',
      data: {
        'device_id': deviceId,
        'platform': platform,
        'token': token,
      },
    );
  }

  /// Read the user's notification preferences. Backend auto-creates
  /// default values on first call so this never 404s.
  Future<NotificationPreferences> getPreferences() async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/notifications/preferences/',
    );
    return NotificationPreferences.fromJson(resp.data ?? const {});
  }

  /// Partial update — send only the keys that changed (use
  /// [NotificationPreferences.diffJson] to compute the delta).
  Future<NotificationPreferences> updatePreferences(
    Map<String, dynamic> delta,
  ) async {
    final resp = await _dio.patch<Map<String, dynamic>>(
      '/notifications/preferences/',
      data: delta,
    );
    return NotificationPreferences.fromJson(resp.data ?? const {});
  }
}


final notificationsApiProvider = Provider<NotificationsApi>((ref) {
  return NotificationsApi(ref.watch(dioProvider));
});
