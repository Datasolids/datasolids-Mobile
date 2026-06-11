// Best-effort human-readable device model name shown on the Active
// Sessions screen instead of the generic "Android phone" / "iPhone"
// fallback we used to ship.
//
// Resolved once at bootstrap and sent on every request as the
// `X-Device-Name` header. The backend prefers this over its UA-sniffed
// label.
//
// Examples (real values from device_info_plus 11.x):
//   Android: "Galaxy S24 Ultra" (marketingName), or
//            "Samsung SM-S928B" when marketingName is empty
//   iOS:     "iPhone 15 Pro Max" (mapped from utsname.machine
//            "iPhone16,2"), or "iPhone" if the identifier is unknown
//   macOS:   "MacBook Pro"
//   Windows: "Windows PC"
//
// We don't ship a full identifier map — the map below covers the
// last ~7 years of iPhones / iPads which is what 99% of users will
// be on. Unknowns degrade to a "iPhone" / "iPad" label rather than
// returning the raw "iPhone15,2" code.

import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';

class DeviceName {
  DeviceName._(this.value);

  /// The user-facing model name. Always non-empty.
  final String value;

  /// Resolve once at boot. Never throws — returns a graceful fallback
  /// when the platform plugin isn't available (e.g. unit tests).
  static Future<DeviceName> resolve() async {
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        final marketing = info.data['marketingName']?.toString() ?? '';
        if (marketing.isNotEmpty) return DeviceName._(marketing);
        final mfg = _title(info.manufacturer);
        final model = info.model;
        if (mfg.isNotEmpty && model.isNotEmpty) {
          // "Samsung SM-S928B" — clear enough until marketingName lands.
          return DeviceName._('$mfg $model');
        }
        return DeviceName._(model.isNotEmpty ? model : 'Android phone');
      }
      if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        final id = info.utsname.machine; // e.g. "iPhone16,2"
        final mapped = _iosMarketingName(id);
        if (mapped != null) return DeviceName._(mapped);
        // Fall back to the model class ("iPhone" / "iPad"). info.name is
        // the user-set device name ("Faisal's iPhone") which is PII-ish
        // so we don't ship it to the server by default.
        return DeviceName._(info.model.isNotEmpty ? info.model : 'iPhone');
      }
      if (Platform.isMacOS) {
        final info = await plugin.macOsInfo;
        return DeviceName._(info.model.isNotEmpty ? info.model : 'Mac');
      }
      if (Platform.isWindows) {
        return DeviceName._('Windows PC');
      }
      if (Platform.isLinux) {
        return DeviceName._('Linux');
      }
    } catch (_) {
      // Plugin failure — fall through to a safe default.
    }
    return DeviceName._('Unknown device');
  }

  static String _title(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  /// Map of iOS hardware identifier → marketing name. Covers iPhone X
  /// onwards; older models degrade to "iPhone". Add new entries here
  /// as Apple ships new hardware.
  static String? _iosMarketingName(String id) {
    return const {
      // iPhone X / Xs / Xr
      'iPhone10,3': 'iPhone X',
      'iPhone10,6': 'iPhone X',
      'iPhone11,2': 'iPhone XS',
      'iPhone11,4': 'iPhone XS Max',
      'iPhone11,6': 'iPhone XS Max',
      'iPhone11,8': 'iPhone XR',
      // iPhone 11
      'iPhone12,1': 'iPhone 11',
      'iPhone12,3': 'iPhone 11 Pro',
      'iPhone12,5': 'iPhone 11 Pro Max',
      // iPhone SE 2 / 12
      'iPhone12,8': 'iPhone SE (2nd gen)',
      'iPhone13,1': 'iPhone 12 mini',
      'iPhone13,2': 'iPhone 12',
      'iPhone13,3': 'iPhone 12 Pro',
      'iPhone13,4': 'iPhone 12 Pro Max',
      // iPhone 13
      'iPhone14,2': 'iPhone 13 Pro',
      'iPhone14,3': 'iPhone 13 Pro Max',
      'iPhone14,4': 'iPhone 13 mini',
      'iPhone14,5': 'iPhone 13',
      // iPhone SE 3 / 14
      'iPhone14,6': 'iPhone SE (3rd gen)',
      'iPhone14,7': 'iPhone 14',
      'iPhone14,8': 'iPhone 14 Plus',
      'iPhone15,2': 'iPhone 14 Pro',
      'iPhone15,3': 'iPhone 14 Pro Max',
      // iPhone 15
      'iPhone15,4': 'iPhone 15',
      'iPhone15,5': 'iPhone 15 Plus',
      'iPhone16,1': 'iPhone 15 Pro',
      'iPhone16,2': 'iPhone 15 Pro Max',
      // iPhone 16
      'iPhone17,1': 'iPhone 16 Pro',
      'iPhone17,2': 'iPhone 16 Pro Max',
      'iPhone17,3': 'iPhone 16',
      'iPhone17,4': 'iPhone 16 Plus',
      // iPad — last few generations only
      'iPad13,1': 'iPad Air (4th gen)',
      'iPad13,2': 'iPad Air (4th gen)',
      'iPad13,4': 'iPad Pro 11" (3rd gen)',
      'iPad13,5': 'iPad Pro 11" (3rd gen)',
      'iPad13,6': 'iPad Pro 11" (3rd gen)',
      'iPad13,7': 'iPad Pro 11" (3rd gen)',
      'iPad13,8': 'iPad Pro 12.9" (5th gen)',
      'iPad13,9': 'iPad Pro 12.9" (5th gen)',
      'iPad13,10': 'iPad Pro 12.9" (5th gen)',
      'iPad13,11': 'iPad Pro 12.9" (5th gen)',
      'iPad14,1': 'iPad mini (6th gen)',
      'iPad14,2': 'iPad mini (6th gen)',
      'iPad14,3': 'iPad Pro 11" (4th gen)',
      'iPad14,4': 'iPad Pro 11" (4th gen)',
      'iPad14,5': 'iPad Pro 12.9" (6th gen)',
      'iPad14,6': 'iPad Pro 12.9" (6th gen)',
    }[id];
  }
}
