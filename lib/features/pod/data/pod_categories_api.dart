// Pod Categories API — wraps GET /pods/me/categories/.

import 'package:datasolids_mobile/core/network/dio_client.dart';
import 'package:datasolids_mobile/features/pod/data/dtos/pod_categories.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PodCategoriesApi {
  PodCategoriesApi(this._dio);
  final Dio _dio;

  Future<PodCategoriesSummary> getCategories() async {
    final resp =
        await _dio.get<Map<String, dynamic>>('/pods/me/categories/');
    return PodCategoriesSummary.fromJson(resp.data ?? const {});
  }
}

final podCategoriesApiProvider = Provider<PodCategoriesApi>((ref) {
  return PodCategoriesApi(ref.watch(dioProvider));
});
