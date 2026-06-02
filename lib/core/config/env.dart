import 'package:datasolids_mobile/core/config/flavor.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Immutable runtime configuration. Build it once in `bootstrap.dart`
/// from the active flavor + --dart-define values + the .env fallback,
/// then read it from anywhere as `Env.instance`.
///
/// **Resolution order for every key:**
///   1. `--dart-define` (compile-time, preferred)
///   2. dotenv (runtime .env file)
///   3. Hard-coded fallback for the flavor
class Env {
  Env._({
    required this.flavor,
    required this.apiBaseUrl,
    required this.sentryDsn,
    required this.analyticsKey,
  });

  static late Env _instance;
  static Env get instance => _instance;

  final Flavor flavor;
  final String apiBaseUrl;
  final String sentryDsn;
  final String analyticsKey;

  bool get sentryEnabled => sentryDsn.isNotEmpty && flavor != Flavor.development;

  static void initialize({required Flavor flavor}) {
    _instance = Env._(
      flavor: flavor,
      apiBaseUrl: _read('API_BASE_URL', fallback: _defaultApiBaseUrl(flavor)),
      sentryDsn: _read('SENTRY_DSN', fallback: ''),
      analyticsKey: _read('ANALYTICS_KEY', fallback: ''),
    );
  }

  static String _read(String key, {required String fallback}) {
    const defined = String.fromEnvironment('__placeholder__');
    // Compile-time --dart-define has top priority.
    final compile = String.fromEnvironment(key);
    if (compile.isNotEmpty && compile != defined) return compile;
    // Then .env.
    final runtime = dotenv.maybeGet(key);
    if (runtime != null && runtime.isNotEmpty) return runtime;
    return fallback;
  }

  static String _defaultApiBaseUrl(Flavor flavor) {
    switch (flavor) {
      case Flavor.development:
        return 'http://localhost:8000';
      case Flavor.staging:
        return 'https://staging.api.datasolids.com';
      case Flavor.production:
        return 'https://api.datasolids.com';
    }
  }
}
