import 'package:datasolids_mobile/core/logging/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Logs every provider lifecycle event in dev / staging. In production
/// only failures land in the log (and Sentry).
class AppProviderObserver extends ProviderObserver {
  const AppProviderObserver();

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    appLogger.e(
      'Provider failed: ${provider.name ?? provider.runtimeType}',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
