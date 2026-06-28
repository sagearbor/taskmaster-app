import 'package:uuid/uuid.dart';

import '../../models/task.dart';

/// Stable identifiers for the AR mini-games. Stored on [Task.arGameId] and used
/// by [ARTaskScreen] to launch the matching game. Keep these strings stable —
/// they are persisted in Firestore game documents.
class ArGameIds {
  static const String balloonPop = 'ar_balloon_pop';
  static const String treasureHunt = 'ar_treasure_hunt';
}

/// Plugin-agnostic configuration for a single AR tap mini-game. Both Balloon Pop
/// and Treasure Hunt are the SAME engine (place glTF nodes, tap to remove,
/// auto-score) with different parameters and a different scoring rule — there is
/// no per-game rendering code, only data.
class ArGameConfig {
  final String id;
  final String title;

  /// Asset path of the glTF model placed for each object.
  final String modelRef;

  /// How many objects are present at once.
  final int objectCount;

  /// Total round length.
  final Duration duration;

  /// Balloon Pop respawns a fresh balloon after each pop (endless within the
  /// timer). Treasure Hunt does not — there are exactly [objectCount] gems.
  final bool respawnOnHit;

  /// Points awarded per object tapped.
  final int pointsPerHit;

  /// Treasure Hunt awards a speed bonus (the seconds left when every gem is
  /// found). Balloon Pop does not.
  final bool speedBonus;

  const ArGameConfig({
    required this.id,
    required this.title,
    required this.modelRef,
    required this.objectCount,
    required this.duration,
    required this.respawnOnHit,
    required this.pointsPerHit,
    required this.speedBonus,
  });

  /// The integer score that lands on the scoreboard. Pure: no engine state.
  ///
  /// - Balloon Pop: 1 point per pop, unbounded within the timer.
  /// - Treasure Hunt: [pointsPerHit] per gem found, plus a speed bonus equal to
  ///   the whole seconds remaining when ALL gems are found (0 if time ran out
  ///   before finding them all).
  int computeScore({required int hits, required int secondsRemaining}) {
    final base = hits * pointsPerHit;
    if (speedBonus && hits >= objectCount) {
      return base + (secondsRemaining < 0 ? 0 : secondsRemaining);
    }
    return base;
  }

  static const ArGameConfig balloonPop = ArGameConfig(
    id: ArGameIds.balloonPop,
    title: 'Balloon Pop',
    modelRef: 'assets/ar/balloon.glb',
    objectCount: 6,
    duration: Duration(seconds: 45),
    respawnOnHit: true,
    pointsPerHit: 1,
    speedBonus: false,
  );

  static const ArGameConfig treasureHunt = ArGameConfig(
    id: ArGameIds.treasureHunt,
    title: 'Treasure Hunt',
    modelRef: 'assets/ar/gem.glb',
    objectCount: 5,
    duration: Duration(seconds: 60),
    respawnOnHit: false,
    pointsPerHit: 10,
    speedBonus: true,
  );

  /// All playable AR games, keyed by [id].
  static const Map<String, ArGameConfig> all = {
    ArGameIds.balloonPop: balloonPop,
    ArGameIds.treasureHunt: treasureHunt,
  };

  /// Resolve a config by its [arGameId], or null if unknown.
  static ArGameConfig? byId(String? arGameId) => all[arGameId];
}

/// Builds the two ready-to-play AR [Task]s so a game can be created containing
/// them without any manual data entry. Each carries [TaskType.ar], its
/// [Task.arGameId], and a per-task time limit derived from the game config.
class ArTaskSeeds {
  static const Uuid _uuid = Uuid();

  static Task balloonPop() => _fromConfig(
        ArGameConfig.balloonPop,
        description:
            'Pop as many floating balloons as you can in 45 seconds. '
            'Move your phone around to find them and tap to pop!',
      );

  static Task treasureHunt() => _fromConfig(
        ArGameConfig.treasureHunt,
        description:
            'Five gems are hidden around your space. Find and tap all of '
            'them as fast as you can — faster finishes score higher!',
      );

  /// Both AR seed tasks, in display order.
  static List<Task> all() => [balloonPop(), treasureHunt()];

  static Task _fromConfig(ArGameConfig config, {required String description}) {
    return Task(
      id: _uuid.v4(),
      title: config.title,
      description: description,
      taskType: TaskType.ar,
      arGameId: config.id,
      durationSeconds: config.duration.inSeconds,
      submissions: const [],
    );
  }
}
