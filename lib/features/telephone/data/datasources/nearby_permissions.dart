import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Requests every runtime permission Google Nearby Connections needs for fully
/// offline play, across Android versions:
///
///  * Android 12+ (API 31+): BLUETOOTH_ADVERTISE / CONNECT / SCAN.
///  * All versions: ACCESS_FINE_LOCATION (BLE scanning still requires it).
///  * Android 13+ (API 33+): NEARBY_WIFI_DEVICES (declared `neverForLocation`).
///
/// `permission_handler` no-ops permissions that don't apply to the running OS
/// version (returns `granted`), so requesting the whole set is safe everywhere.
/// Returns true only if the permissions actually required to advertise/scan are
/// granted.
class NearbyPermissions {
  const NearbyPermissions._();

  static Future<bool> request() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    final statuses = await [
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
      Permission.nearbyWifiDevices,
    ].request();

    // A permission that doesn't apply to this OS version comes back as
    // `granted` (no-op) or `restricted`; only treat an explicit denial as a
    // blocker. Location OR the Bluetooth-scan trio must be usable to proceed.
    bool ok(Permission p) {
      final s = statuses[p];
      return s == null || s.isGranted || s.isLimited || s.isRestricted;
    }

    final bluetoothOk = ok(Permission.bluetoothAdvertise) &&
        ok(Permission.bluetoothConnect) &&
        ok(Permission.bluetoothScan);

    return bluetoothOk && ok(Permission.location);
  }

  /// Whether the platform can run Nearby at all (Android, non-web).
  static bool get isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}
