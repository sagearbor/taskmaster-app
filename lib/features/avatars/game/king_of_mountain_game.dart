import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import '../../../core/models/player.dart';
import 'components/player_avatar.dart';
import 'components/platform_component.dart';
import 'components/npc_avatar.dart';

/// King of the Mountain - Physics-based avatar climbing game
/// Avatars autonomously try to reach the top platform while pushing each other
class KingOfMountainGame extends Forge2DGame {
  final List<Player> players;
  final double worldWidth = 800;
  final double worldHeight = 1200;

  final List<PlayerAvatar> _avatars = [];
  final List<PlatformComponent> _platforms = [];

  PlayerAvatar? _currentKing;

  KingOfMountainGame({
    required this.players,
  }) : super(gravity: Vector2(0, 30)); // Gravity pulls down

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Set camera bounds
    camera.viewport = FixedResolutionViewport(Vector2(worldWidth, worldHeight));

    // Create platforms at different heights
    await _createPlatforms();

    // Create avatars for real players
    await _createPlayerAvatars();

    // Fill remaining slots with NPCs (max 10 total)
    await _createNPCAvatars();

    // Add boundaries (walls)
    await _createBoundaries();
  }

  Future<void> _createPlatforms() async {
    // Ground platform
    final ground = PlatformComponent(
      position: Vector2(worldWidth / 2, worldHeight - 50),
      width: worldWidth * 0.9,
      height: 20,
      isGround: true,
    );
    await add(ground);
    _platforms.add(ground);

    // Middle platforms (staggered)
    final platform1 = PlatformComponent(
      position: Vector2(worldWidth * 0.3, worldHeight - 250),
      width: worldWidth * 0.4,
      height: 15,
    );
    await add(platform1);
    _platforms.add(platform1);

    final platform2 = PlatformComponent(
      position: Vector2(worldWidth * 0.7, worldHeight - 450),
      width: worldWidth * 0.35,
      height: 15,
    );
    await add(platform2);
    _platforms.add(platform2);

    final platform3 = PlatformComponent(
      position: Vector2(worldWidth * 0.35, worldHeight - 650),
      width: worldWidth * 0.3,
      height: 15,
    );
    await add(platform3);
    _platforms.add(platform3);

    // Top platform (the peak - only 2 avatars can fit)
    final peak = PlatformComponent(
      position: Vector2(worldWidth / 2, worldHeight - 900),
      width: worldWidth * 0.25,
      height: 15,
      isPeak: true,
    );
    await add(peak);
    _platforms.add(peak);
  }

  Future<void> _createPlayerAvatars() async {
    final startSpacing = worldWidth / (players.length + 1);

    for (var i = 0; i < players.length; i++) {
      final avatar = PlayerAvatar(
        player: players[i],
        startPosition: Vector2(
          startSpacing * (i + 1),
          worldHeight - 150, // Start just above ground
        ),
        platforms: _platforms,
      );
      await add(avatar);
      _avatars.add(avatar);
    }
  }

  Future<void> _createNPCAvatars() async {
    const maxAvatars = 10;
    final npcCount = (maxAvatars - players.length).clamp(0, 8);

    final animalEmojis = ['🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼'];

    final startX = worldWidth / (npcCount + players.length + 1);

    for (var i = 0; i < npcCount; i++) {
      final npcAvatar = NPCAvatar(
        emoji: animalEmojis[i % animalEmojis.length],
        name: 'NPC ${i + 1}',
        startPosition: Vector2(
          startX * (i + players.length + 1),
          worldHeight - 150,
        ),
        platforms: _platforms,
      );
      await add(npcAvatar);
      _avatars.add(npcAvatar);
    }
  }

  Future<void> _createBoundaries() async {
    // Left wall
    final leftWall = WallComponent(
      position: Vector2(10, worldHeight / 2),
      height: worldHeight,
    );
    await add(leftWall);

    // Right wall
    final rightWall = WallComponent(
      position: Vector2(worldWidth - 10, worldHeight / 2),
      height: worldHeight,
    );
    await add(rightWall);

    // Ceiling
    final ceiling = WallComponent(
      position: Vector2(worldWidth / 2, 10),
      height: 20,
      isHorizontal: true,
      width: worldWidth,
    );
    await add(ceiling);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _checkForKing();
  }

  void _checkForKing() {
    // Find avatar closest to the peak
    final peakPlatform = _platforms.firstWhere((p) => p.isPeak);
    final peakY = peakPlatform.position.y;

    PlayerAvatar? newKing;
    double minDistance = double.infinity;

    for (final avatar in _avatars) {
      final distance = (avatar.body.position.y - peakY).abs();
      if (distance < minDistance && distance < 50) { // Within 50 units of peak
        minDistance = distance;
        newKing = avatar;
      }
    }

    if (newKing != _currentKing) {
      _currentKing?.setIsKing(false);
      newKing?.setIsKing(true);
      _currentKing = newKing;
    }
  }

  List<PlayerAvatar> get avatars => _avatars;
  PlayerAvatar? get currentKing => _currentKing;
}

/// Wall component for boundaries
class WallComponent extends BodyComponent {
  final Vector2 position;
  final double height;
  final double width;
  final bool isHorizontal;

  WallComponent({
    required this.position,
    required this.height,
    this.width = 20,
    this.isHorizontal = false,
  });

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      position: position,
      type: BodyType.static,
    );

    final shape = PolygonShape()
      ..setAsBox(
        isHorizontal ? width / 2 : width / 2,
        isHorizontal ? 10 : height / 2,
        Vector2.zero(),
        0,
      );

    final fixtureDef = FixtureDef(shape)
      ..friction = 0.3
      ..restitution = 0.1;

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }
}
