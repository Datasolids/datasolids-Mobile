// Shared boot for every flavor.
//
// Responsibilities:
//   1. WidgetsFlutterBinding ensures the platform is ready before
//      we touch the screen.
//   2. Locks orientation to portrait (we ship a phone-first layout in
//      v1; tablets land in v2).
//   3. Installs the global error handlers BEFORE Sentry initializes
//      so even pre-Sentry crashes surface as logs.
//   4. Initialises the runtime config from --dart-define values, with
//      a .env file fallback so devs running `flutter run` without args
//      still get sane defaults.
//   5. Wraps the App tree in ProviderScope + Sentry's runZonedGuarded.
//
// Nothing in this file does feature work. Feature wiring lives in
// `app/app.dart` and the per-feature providers.

import 'dart:async';

import 'package:datasolids_mobile/app/app.dart';
import 'package:datasolids_mobile/app/observers.dart';
import 'package:datasolids_mobile/core/config/env.dart';
import 'package:datasolids_mobile/core/config/flavor.dart';
import 'package:datasolids_mobile/core/device/device_id.dart';
import 'package:datasolids_mobile/core/device/device_name.dart';
import 'package:datasolids_mobile/core/logging/logger.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:sentry_flutter/sentry_flutter.dart';
// ↑ Disabled — see pubspec.yaml note. Re-enable when Sentry is
// reconfigured to play nicely with SPM + the Podfile pin.
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/flavor.dart';

Future<void> bootstrap({required Flavor flavor}) async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Portrait-only for the v1 mobile design.
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // .env loader for non-CI dev runs. CI sets values via --dart-define.
      try {
        await dotenv.load(fileName: flavor.envFileName);
      } catch (_) {
        // .env file missing is OK — we fall back to defaults.
      }

      // Build the immutable runtime config.
      Env.initialize(flavor: flavor);

      // Open SharedPreferences once, then materialize the per-install
      // device id so the Dio interceptor can stamp X-Device-Id on
      // every request synchronously. We hold on to the SAME manager
      // instance and inject it into the provider below — building a
      // fresh manager inside the provider would lose the loaded value.
      final prefs = await SharedPreferences.getInstance();
      final deviceIdManager = DeviceIdManager(prefs);
      await deviceIdManager.load();
      // Resolve the real device model name (e.g. "Galaxy S24 Ultra")
      // so the Active Sessions screen can show "Galaxy S24 Ultra"
      // instead of the generic "Android phone".
      final deviceName = (await DeviceName.resolve()).value;

      // Pre-Sentry error trap. Anything thrown before we wire Sentry
      // below still reaches the log.
      FlutterError.onError = (details) {
        appLogger.e(
          'FlutterError',
          error: details.exception,
          stackTrace: details.stack,
        );
      };

      // Sentry — production + staging only. In dev we want stack traces
      // in the console, not in someone's dashboard.
      Future<void> runApp() async {
        runApp_(
          ProviderScope(
            observers: const [AppProviderObserver()],
            overrides: [
              // The provider declarations throw by default — we supply
              // the real opened SharedPreferences and the already-
              // loaded DeviceIdManager so feature code can read both
              // synchronously via ref.watch.
              sharedPreferencesProvider.overrideWithValue(prefs),
              deviceIdManagerProvider.overrideWithValue(deviceIdManager),
              deviceModelNameProvider.overrideWithValue(deviceName),
            ],
            child: const DatasolidsApp(),
          ),
        );
      }

      // Sentry temporarily disabled — runApp directly. When sentry_flutter
      // is re-enabled in pubspec.yaml, restore the if/else with
      // SentryFlutter.init(..., appRunner: runApp) here.
      await runApp();
    },
    (error, stack) {
      appLogger.e('Uncaught zone error', error: error, stackTrace: stack);
      // Sentry capture also disabled; surface via the local logger only.
    },
  );
}

/// Indirection so tests can swap the runner.
// void runApp_(Widget app) => WidgetsFlutterBinding.ensureInitialized().attachRootWidget(app);

void runApp_(Widget app) => runApp(app);