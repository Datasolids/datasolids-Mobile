// Per-category list + resource detail API.

import 'package:datasolids_mobile/core/network/dio_client.dart';
import 'package:datasolids_mobile/features/pod/data/dtos/category_resource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryResourcesApi {
  CategoryResourcesApi(this._dio);
  final Dio _dio;

  /// One page of a category's resources.
  ///
  /// `filter` is "all" (default), "abnormal" (labs only), "recent",
  /// or "active" (medications). `sort` is "date_desc" (default),
  /// "date_asc", or "title_asc". `q` is a free-text title filter.
  Future<CategoryResourcesPage> getList({
    required String categoryKey,
    String filter = 'all',
    String sort = 'date_desc',
    int offset = 0,
    int limit = 20,
    String? q,
  }) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/pods/me/categories/$categoryKey/resources/',
      queryParameters: {
        'filter': filter,
        'sort': sort,
        'offset': offset,
        'limit': limit,
        if (q != null && q.isNotEmpty) 'q': q,
      },
    );
    return CategoryResourcesPage.fromJson(resp.data ?? const {});
  }

  Future<ResourceDetail> getDetail(String resourceId) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/pods/me/resources/$resourceId/',
    );
    return ResourceDetail.fromJson(resp.data ?? const {});
  }
}

final categoryResourcesApiProvider = Provider<CategoryResourcesApi>((ref) {
  return CategoryResourcesApi(ref.watch(dioProvider));
});
