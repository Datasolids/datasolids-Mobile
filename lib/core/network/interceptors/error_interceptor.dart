import 'package:datasolids_mobile/core/errors/app_failure.dart';
import 'package:dio/dio.dart';

/// Wraps Dio errors into our typed `AppFailure` so features never
/// catch `DioException` directly.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: AppFailure.fromDio(err),
        message: err.message,
      ),
    );
  }
}
