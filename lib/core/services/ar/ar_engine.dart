import 'package:flutter/widgets.dart';

/// A detected AR plane (e.g. a floor or table) the player can place objects on.
class ArPlane {
  final String id;

  const ArPlane(this.id);
}

/// A tap on an AR object (e.g. popping a balloon), identified by the spawned
/// node's id.
class ArTap {
  final String nodeId;

  const ArTap(this.nodeId);
}

/// A handle to a spawned AR object so it can be referenced later.
class ArNode {
  final String id;

  const ArNode(this.id);
}

/// Plugin-AGNOSTIC boundary for AR rendering. Nothing above this interface may
/// import an AR plugin — only the concrete engine implementation does. This
/// keeps the AR mini-game logic, the capability gating, and all tests free of
/// any plugin dependency, and lets us swap the underlying plugin (or fall back
/// to model_viewer_plus) without touching callers.
abstract class ArEngine {
  /// Build the platform AR view widget. Must be hosted by the engine impl.
  Widget buildView();

  /// Initialize the AR session (camera + tracking). Throws nothing the caller
  /// must handle for capability — capability is decided upstream by
  /// ArCapabilityService; this is the render-session bring-up.
  Future<void> initSession();

  /// Stream of detected planes as tracking discovers surfaces.
  Stream<ArPlane> get planes;

  /// Spawn an object (e.g. a balloon) at a plane/anchor, returning its node.
  Future<ArNode> spawn({required String modelRef, ArPlane? onPlane});

  /// Stream of taps on spawned objects (e.g. balloon pops).
  Stream<ArTap> get taps;

  /// Tear down the AR session and release the camera.
  Future<void> dispose();
}
