import 'dart:async';

import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/widgets/ar_view.dart';
import 'package:flutter/widgets.dart';

import 'ar_engine.dart';

/// The ONE file that imports the AR plugin (`ar_flutter_plugin_2`). Everything
/// else in the app talks to [ArEngine] only, so the plugin can be swapped or
/// replaced with a fallback (e.g. model_viewer_plus) by editing just this file.
///
/// NOTE: This is the render-boundary wiring required to PROVE the plugin builds.
/// The actual Balloon Pop placement/scoring logic renders on a physical device
/// in the next phase; [spawn] is intentionally left for that phase.
class ArFlutterEngine implements ArEngine {
  ARSessionManager? _sessionManager;
  ARObjectManager? _objectManager;
  ARAnchorManager? _anchorManager;

  final StreamController<ArPlane> _planeController =
      StreamController<ArPlane>.broadcast();
  final StreamController<ArTap> _tapController =
      StreamController<ArTap>.broadcast();

  @override
  Widget buildView() {
    return ARView(
      onARViewCreated: _onViewCreated,
      planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
    );
  }

  void _onViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    _sessionManager = sessionManager;
    _objectManager = objectManager;
    _anchorManager = anchorManager;

    sessionManager.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      handleTaps: true,
    );
    objectManager.onInitialize();

    // Bridge plugin callbacks onto the plugin-agnostic streams.
    sessionManager.onPlaneOrPointTap = (hits) {
      if (hits.isNotEmpty) {
        _planeController.add(const ArPlane('detected'));
      }
    };
    objectManager.onNodeTap = (nodes) {
      for (final node in nodes) {
        _tapController.add(ArTap(node));
      }
    };
  }

  @override
  Future<void> initSession() async {
    // Session bring-up happens in [_onViewCreated] once the platform view is
    // created; nothing extra is required here for the build-proof scaffold.
  }

  @override
  Stream<ArPlane> get planes => _planeController.stream;

  @override
  Stream<ArTap> get taps => _tapController.stream;

  @override
  Future<ArNode> spawn({required String modelRef, ArPlane? onPlane}) async {
    // Real object placement (anchor + ARNode with the balloon model) lands in
    // the next, device-tested phase. Anchor manager is captured above ready
    // for that work.
    assert(_anchorManager != null, 'AR view not created yet');
    throw UnimplementedError(
      'Balloon placement is implemented in the device-testing phase.',
    );
  }

  @override
  Future<void> dispose() async {
    _sessionManager?.dispose();
    await _planeController.close();
    await _tapController.close();
    _sessionManager = null;
    _objectManager = null;
    _anchorManager = null;
  }
}
