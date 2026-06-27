import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// The result of probing whether this device can run an AR task.
enum ArSupport {
  /// Device + camera are ready for AR.
  supported,

  /// Platform cannot do AR at all (web, desktop, etc.).
  unsupportedPlatform,

  /// Android device where Google Play Services for AR (ARCore) is missing or
  /// out of date and needs an install/update before AR can run.
  needsArCoreUpdate,

  /// The user has denied the camera permission AR requires.
  cameraDenied,

  /// Something unexpected happened while probing. Treated as non-fatal: the UI
  /// should fall back gracefully rather than crash.
  unknownError,
}

/// Abstracts the "can this device run AR?" decision so the UI and tests never
/// touch a plugin or platform channel directly. Implementations must NEVER
/// throw — every failure maps to an [ArSupport] value.
abstract class ArCapabilityService {
  /// Probe device capability. Order of precedence is important: web first,
  /// then non-mobile platforms, then camera permission, then AR availability.
  Future<ArSupport> check();

  /// Request the camera permission. Returns true if it is (now) granted.
  /// Never throws.
  Future<bool> requestCamera();

  /// Open the OS app-settings page so the user can re-grant a permanently
  /// denied permission. Never throws.
  Future<void> openSettings();
}

/// Default implementation. Deliberately plugin-agnostic: it relies only on
/// platform detection + [permission_handler]. Deeper ARCore/ARKit availability
/// queries belong to the [ArEngine] layer (added with the AR plugin); until
/// then a camera-capable iOS/Android device is reported as [ArSupport.supported].
class ArCapabilityServiceImpl implements ArCapabilityService {
  /// Whether the app is running on the web. Defaults to the real [kIsWeb];
  /// overridable so the web→unsupported path is unit-testable off-device.
  final bool isWeb;

  /// The target platform. Defaults to the real [defaultTargetPlatform];
  /// overridable for tests.
  final TargetPlatform platform;

  /// Probes the current camera permission status. Defaults to the real
  /// [permission_handler] lookup; overridable for tests so they need no
  /// platform channel.
  final Future<PermissionStatus> Function() cameraStatus;

  ArCapabilityServiceImpl({
    bool? isWeb,
    TargetPlatform? platform,
    Future<PermissionStatus> Function()? cameraStatus,
  })  : isWeb = isWeb ?? kIsWeb,
        platform = platform ?? defaultTargetPlatform,
        cameraStatus = cameraStatus ?? (() => Permission.camera.status);

  @override
  Future<ArSupport> check() async {
    try {
      // 1. Web has no AR support in this app — check FIRST so we never touch a
      //    mobile-only plugin or platform channel on web.
      if (isWeb) {
        return ArSupport.unsupportedPlatform;
      }

      // 2. Only iOS and Android can run AR. Everything else is unsupported.
      final isMobile =
          platform == TargetPlatform.iOS || platform == TargetPlatform.android;
      if (!isMobile) {
        return ArSupport.unsupportedPlatform;
      }

      // 3. Camera permission gate. A permanently-denied/denied camera means we
      //    surface cameraDenied so the UI can deep-link to settings.
      final status = await cameraStatus();
      if (status.isPermanentlyDenied || status.isDenied || status.isRestricted) {
        return ArSupport.cameraDenied;
      }

      // 4. Camera is available. Deeper ARCore availability (needsArCoreUpdate)
      //    is resolved by the ArEngine once the plugin is wired in; a
      //    camera-ready mobile device is considered supported here.
      return ArSupport.supported;
    } catch (_) {
      // Never propagate to the UI — fall back to a recoverable error state.
      return ArSupport.unknownError;
    }
  }

  @override
  Future<bool> requestCamera() async {
    try {
      final result = await Permission.camera.request();
      return result.isGranted;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> openSettings() async {
    try {
      await openAppSettings();
    } catch (_) {
      // Best-effort: nothing more we can do if the OS refuses to open settings.
    }
  }
}
