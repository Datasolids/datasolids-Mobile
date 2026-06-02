import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

/// Domain-level error type. Every feature returns
/// `Either<AppFailure, T>` from its repository methods so the UI
/// never sees a raw `DioException`.
sealed class AppFailure extends Equatable {
  const AppFailure({required this.message, this.code, this.detail});
  final String message;
  final String? code;
  final Object? detail;

  factory AppFailure.fromDio(DioException e) {
    final response = e.response;
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkFailure(message: 'Connection timed out.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return const NetworkFailure(
        message: "We couldn't reach the server. Check your connection.",
      );
    }
    if (response == null) {
      return UnknownFailure(message: e.message ?? 'Unknown error.');
    }
    final code = response.statusCode ?? 0;
    final body = response.data;
    final detail = body is Map ? body['detail']?.toString() : null;

    if (code == 401) {
      return UnauthorizedFailure(message: detail ?? 'Please sign in again.');
    }
    if (code == 403) {
      return ForbiddenFailure(
        message: detail ?? 'You do not have access to this resource.',
      );
    }
    if (code == 404) {
      return NotFoundFailure(message: detail ?? 'Not found.');
    }
    if (code == 429) {
      return RateLimitedFailure(
        message: detail ?? 'Too many attempts. Try again in a minute.',
      );
    }
    if (code >= 500) {
      return ServerFailure(
        message: detail ?? "Something broke on our end. We're looking into it.",
        code: code.toString(),
      );
    }
    return ValidationFailure(
      message: detail ?? 'Please check your input.',
      code: code.toString(),
      detail: body,
    );
  }

  @override
  List<Object?> get props => [message, code, detail];
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure({required super.message}) : super(code: 'network');
}

final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure({required super.message}) : super(code: '401');
}

final class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure({required super.message}) : super(code: '403');
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure({required super.message}) : super(code: '404');
}

final class RateLimitedFailure extends AppFailure {
  const RateLimitedFailure({required super.message}) : super(code: '429');
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure({
    required super.message,
    super.code,
    super.detail,
  });
}

final class ServerFailure extends AppFailure {
  const ServerFailure({required super.message, super.code});
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure({required super.message}) : super(code: 'unknown');
}
