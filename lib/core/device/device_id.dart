// Per-install stable device identifier.
//
// Generated on first launch and persisted to SharedPreferences so it
// survives logout, app restart, app upgrade. Wiped only on app
// uninstall. Sent on every request as the `X-Device-Id` header so the
// backend can dedupe LoginSession rows per physical device instead of
// per refresh-token family (which rotates on every login).
//
// We deliberately do NOT use a hardware ID (Android ID, iOS
// identifierForVendor). Those tie the row to the silicon, which makes
// it hard for users to wipe a stolen-phone session by uninstalling.
// A per-install UUID gives the right semantics: uninstalling the app
// invalidates the session row from the user's perspective.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdManager {
  DeviceIdManager(this._prefs);

  static const _key = 'datasolids.device_id.v1';

  final SharedPreferences _prefs;

  /// Cached so callers (Dio interceptor, login screen) can read
  /// synchronously after `load()` has run during bootstrap.
  String? _cached;

  String get value {
    final v = _cached;
    if (v == null) {
      throw StateError(
        'DeviceIdManager.load() must be awaited during bootstrap '
        'before reading the device id.',
      );
    }
    return v;
  }

  Future<String> load() async {
    if (_cached != null) return _cached!;
    var v = _prefs.getString(_key);
    if (v == null || v.isEmpty) {
      v = const Uuid().v4();
      await _prefs.setString(_key, v);
    }
    _cached = v;
    return v;
  }
}

/// Holds the SharedPreferences instance the app boots with.
/// Initialized in bootstrap before runApp.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in bootstrap with '
    'the awaited SharedPreferences.getInstance() result.',
  );
});

final deviceIdManagerProvider = Provider<DeviceIdManager>((ref) {
  return DeviceIdManager(ref.watch(sharedPreferencesProvider));
});

/// Resolved device model name (e.g. "Galaxy S24 Ultra", "iPhone 15 Pro").
/// Injected by bootstrap; throws if read before bootstrap finishes so we
/// catch wiring bugs early instead of shipping "Android phone" forever.
final deviceModelNameProvider = Provider<String>((ref) {
  throw UnimplementedError(
    'deviceModelNameProvider must be overridden in bootstrap with the '
    'awaited DeviceName.resolve() result.',
  );
});
