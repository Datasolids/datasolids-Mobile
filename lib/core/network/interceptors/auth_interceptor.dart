import 'dart:async';

import 'package:datasolids_mobile/core/auth/token_manager.dart';
import 'package:datasolids_mobile/core/logging/logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Attaches the access token to every outgoing request, and refreshes
/// it transparently on 401. Refresh is serialised via a single
/// Completer so 50 parallel 401s only trigger ONE refresh — the others
/// wait, then retry with the new token.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._ref);

  final Ref _ref;
  Completer<void>? _refreshCompleter;

  // Public-ish endpoints that should never see an Authorization header.
  static const _publicPaths = <String>{
    '/auth/login/',
    '/auth/signup/patient/',
    '/auth/signup/researcher/',
    '/auth/token/refresh/',
    '/auth/password-reset/request/',
    '/auth/password-reset/confirm/',
    '/auth/verify-email/',
    '/auth/invite/accept/',
  };

  bool _isPublic(RequestOptions opts) {
    return _publicPaths.any((p) => opts.path.endsWith(p));
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isPublic(options)) {
      handler.next(options);
      return;
    }
    // If a refresh is in-flight, wait for it.
    if (_refreshCompleter != null) {
      await _refreshCompleter!.future;
    }
    final token = await _ref.read(tokenManagerProvider).getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final code = response.statusCode ?? 0;
    if (code != 401 || _isPublic(response.requestOptions)) {
      handler.next(response);
      return;
    }
    // 401 on an authenticated call → refresh + retry once.
    final retried = await _refreshAndRetry(response.requestOptions);
    if (retried != null) {
      handler.resolve(retried);
    } else {
      handler.next(response);
    }
  }

  Future<Response<dynamic>?> _refreshAndRetry(
    RequestOptions options,
  ) async {
    final tokens = _ref.read(tokenManagerProvider);

    if (_refreshCompleter != null) {
      await _refreshCompleter!.future;
    } else {
      _refreshCompleter = Completer<void>();
      try {
        final ok = await tokens.refresh();
        if (!ok) {
          await tokens.signOut(reason: 'refresh_failed');
          _refreshCompleter!.complete();
          _refreshCompleter = null;
          return null;
        }
      } catch (e, st) {
        appLogger.w('Token refresh failed', error: e, stackTrace: st);
        await tokens.signOut(reason: 'refresh_exception');
      } finally {
        _refreshCompleter?.complete();
        _refreshCompleter = null;
      }
    }

    // Re-issue the original request with the fresh token.
    final dio = Dio()..options.baseUrl = options.baseUrl;
    final newToken = await tokens.getAccessToken();
    final newOpts = Options(
      method: options.method,
      headers: {
        ...options.headers,
        if (newToken != null) 'Authorization': 'Bearer $newToken',
      },
      contentType: options.contentType,
      responseType: options.responseType,
    );
    try {
      return await dio.request<dynamic>(
        options.path,
        data: options.data,
        queryParameters: options.queryParameters,
        options: newOpts,
      );
    } catch (e, st) {
      appLogger.w('Retry after refresh failed', error: e, stackTrace: st);
      return null;
    }
  }
}
