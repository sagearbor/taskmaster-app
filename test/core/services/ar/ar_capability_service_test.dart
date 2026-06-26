import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:taskcaster_app/core/services/ar/ar_capability_service.dart';

/// STEP 3: capability gating must never crash and must short-circuit web to
/// [ArSupport.unsupportedPlatform] BEFORE touching any mobile-only plugin.
void main() {
  group('ArCapabilityServiceImpl.check', () {
    test('web is reported as unsupportedPlatform (checked first)', () async {
      // isWeb true short-circuits before any platform-channel/permission call.
      // The throwing cameraStatus proves we never reach the permission probe.
      final service = ArCapabilityServiceImpl(
        isWeb: true,
        platform: TargetPlatform.android,
        cameraStatus: () async => throw StateError('must not be called on web'),
      );

      expect(await service.check(), ArSupport.unsupportedPlatform);
    });

    test('non-mobile platform (e.g. desktop) is unsupportedPlatform', () async {
      final service = ArCapabilityServiceImpl(
        isWeb: false,
        platform: TargetPlatform.macOS,
        cameraStatus: () async => PermissionStatus.granted,
      );

      expect(await service.check(), ArSupport.unsupportedPlatform);
    });

    test('mobile + granted camera is supported', () async {
      final service = ArCapabilityServiceImpl(
        isWeb: false,
        platform: TargetPlatform.android,
        cameraStatus: () async => PermissionStatus.granted,
      );

      expect(await service.check(), ArSupport.supported);
    });

    test('mobile + denied camera is cameraDenied', () async {
      final service = ArCapabilityServiceImpl(
        isWeb: false,
        platform: TargetPlatform.iOS,
        cameraStatus: () async => PermissionStatus.denied,
      );

      expect(await service.check(), ArSupport.cameraDenied);
    });

    test('an unexpected error maps to unknownError, never throws', () async {
      final service = ArCapabilityServiceImpl(
        isWeb: false,
        platform: TargetPlatform.android,
        cameraStatus: () async => throw Exception('boom'),
      );

      // Must resolve, not throw.
      expect(await service.check(), ArSupport.unknownError);
    });
  });
}
