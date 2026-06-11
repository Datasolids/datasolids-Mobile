import 'dart:io' show Platform;

import 'package:datasolids_mobile/core/config/env.dart';
import 'package:datasolids_mobile/core/config/flavor.dart';
import 'package:datasolids_mobile/core/network/interceptors/auth_interceptor.dart';
import 'package:datasolids_mobile/core/network/interceptors/error_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

/// Identifies the app + platform to the backend so the Active Sessions
/// screen can show "iPhone" / "Android phone" / "iPad" instead of an
/// unidentified default UA. Bumped manually with each app release.
String _appUserAgent() {
  String platform;
  try {
    if (Platform.isIOS) platform = 'iOS';
    else if (Platform.isAndroid) platform = 'Android';
    else if (Platform.isMacOS) platform = 'macOS';
    else if (Platform.isWindows) platform = 'Windows';
    else if (Platform.isLinux) platform = 'Linux';
    else platform = 'Unknown';
  } catch (_) {
    // dart:io throws on web; fall back to Web so the backend treats it
    // as a browser session.
    platform = 'Web';
  }
  return 'DatasolidsMobile/1.0 ($platform)';
}

/// Single configured Dio instance for the whole app. Feature API clients
/// (Retrofit-generated or hand-written) take this Dio as a constructor
/// arg — they don't construct their own.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: '${Env.instance.apiBaseUrl}/api/v1',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'User-Agent': _appUserAgent(),
      },
      // Don't auto-throw on 4xx — we want to inspect the body. The
      // ErrorInterceptor wraps non-2xx into typed AppFailure later.
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(ref),
    ErrorInterceptor(),
    if (Env.instance.flavor != Flavor.production)
      PrettyDioLogger(
        requestHeader: false,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        compact: true,
        maxWidth: 100,
      ),
  ]);

  return dio;
});
