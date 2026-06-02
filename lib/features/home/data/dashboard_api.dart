// Dashboard API client — wraps GET /pods/me/summary/.

import 'package:datasolids_mobile/core/network/dio_client.dart';
import 'package:datasolids_mobile/features/home/data/dtos/dashboard_summary.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardApi {
  DashboardApi(this._dio);
  final Dio _dio;

  Future<DashboardSummary> getSummary() async {
    final resp = await _dio.get<Map<String, dynamic>>('/pods/me/summary/');
    return DashboardSummary.fromJson(resp.data ?? const {});
  }
}

final dashboardApiProvider = Provider<DashboardApi>((ref) {
  return DashboardApi(ref.watch(dioProvider));
});
