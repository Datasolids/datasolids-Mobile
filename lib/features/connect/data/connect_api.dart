// Connect-EHR API client — Epic org directory search + OAuth start.

import 'package:datasolids_mobile/core/network/dio_client.dart';
import 'package:datasolids_mobile/features/connect/data/dtos/epic_org.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One page of org search results.
class OrgPage {
  const OrgPage({
    required this.results,
    required this.count,
    required this.offset,
    required this.hasMore,
  });

  final List<EpicOrg> results;
  final int count;
  final int offset;
  final bool hasMore;
}

class ConnectApi {
  ConnectApi(this._dio);
  final Dio _dio;

  /// Search the re-hosted Epic endpoint directory. An empty [query] returns
  /// the first page of active orgs. The backend requires a 2+ char query,
  /// so callers should not pass a single char.
  Future<OrgPage> searchOrganizations(
    String query, {
    int offset = 0,
    int limit = 25,
    CancelToken? cancelToken,
  }) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/integrations/epic/organizations/',
      queryParameters: {
        if (query.isNotEmpty) 'q': query,
        'offset': offset,
        'limit': limit,
      },
      cancelToken: cancelToken,
    );
    final data = resp.data ?? const {};
    final results = (data['results'] as List<dynamic>?) ?? const [];
    return OrgPage(
      results: results
          .whereType<Map<String, dynamic>>()
          .map(EpicOrg.fromJson)
          .toList(),
      count: (data['count'] as num?)?.toInt() ?? 0,
      offset: (data['offset'] as num?)?.toInt() ?? offset,
      hasMore: data['has_more'] as bool? ?? false,
    );
  }

  /// Begin the OAuth flow for a chosen health system. Returns the Epic
  /// authorize URL the app should open in an in-app browser session.
  Future<String> startOauth(String endpointId) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/integrations/epic/start/',
      data: {'endpoint_id': endpointId},
    );
    final url = (resp.data?['authorize_url'] ?? '').toString();
    if (url.isEmpty) {
      throw StateError('Server did not return an authorize URL.');
    }
    return url;
  }
}

final connectApiProvider = Provider<ConnectApi>((ref) {
  return ConnectApi(ref.watch(dioProvider));
});
