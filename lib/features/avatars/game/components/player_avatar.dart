import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import '../../../../core/models/player.dart';
import 'platform_component.dart';

enum AvatarState {
  idle,
  walking,
  climbing,
  jumping,
  falling,
  pushing,
}

/// Player avatar with physics-based movement and autonomous AI
class PlayerAvatar extends BodyComponent {
  final Player player;
  final Vector2 startPosition;
  final List<PlatformComponent> platforms;

  // AI movement parameters
  final double moveSpeed = 100.0;
  final double jumpForce = 300.0;
  final double maxSpeed = 150.0;

  // State
  AvatarState state = AvatarState.idle;
  bool _isKing = false;

  // Expose for subclasses
  bool get isKing => _isKing;
  PlatformComponent? _targetPlatform;
  double _timeSinceLastJump = 0;
  final double _jumpCooldown = 1.5;
  bool _isOnGround = false;

  // Visual properties
  final double avatarRadius = 20.0;
  final Random _random = Random();
  double _animationTimer = 0;

  PlayerAvatar({
    required this.player,
    required this.startPosition,
    required this.platforms,
  });

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      position: startPosition,
      type: BodyType.dynamic,
      fixedRotation: true, // Prevent rotation for upright avatars
    );

    final shape = CircleShape()..radius = avatarRadius;

    final fixtureDef = FixtureDef(shape)
      ..density = 1.0
      ..friction = 0.3
      ..restitution = 0.1;

    final body = world.createBody(bodyDef);
    body.createFixture(fixtureDef);

    // Store reference to this avatar in body's userData
    body.userData = this;

    return body;
  }

  @override
  void update(double dt) {
    super.update(dt);

    _animationTimer += dt;
    _timeSinceLastJump += dt;

    // Check if on ground
    _checkGroundContact();

    // Autonomous AI behavior
    updateAI(dt);

    // Update state based on velocity
    _updateState();

    // Limit max speed
    _limitSpeed();
  }

  void _checkGroundContact() {
    // Simple ground check based on velocity
    _isOnGround = body.linearVelocity.y.abs() < 0.5;
  }

  // Make protected for subclasses to override
  @protected
  void updateAI(double dt) {
    // Find target platform (highest platform above us)
    _targetPlatform = _findTargetPlatform();

    if (_targetPlatform != null) {
      final target = _targetPlatform!.position;
      final currentPos = body.position;

      // Horizontal movement toward target
      final dx = target.x - currentPos.x;

      if (dx.abs() > 10) {
        // Move left or right
        final direction = dx > 0 ? 1.0 : -1.0;
        body.applyForce(Vector2(moveSpeed * direction, 0));
      }

      // Jump if we're below the platform and aligned horizontally
      if (_shouldJump(target, currentPos)) {
        _jump();
      }
    } else {
      // No target - wander randomly
      if (_random.nextDouble() < 0.01) {
        final direction = _random.nextBool() ? 1.0 : -1.0;
        body.applyForce(Vector2(moveSpeed * direction, 0));
      }
    }
  }

  PlatformComponent? _findTargetPlatform() {
    final currentY = body.position.y;

    // Find platforms above us
    final platformsAbove = platforms
        .where((p) => p.position.y < currentY - 50)
        .toList()
      ..sort((a, b) => a.position.y.compareTo(b.position.y));

    // Target the lowest platform above us
    return platformsAbove.isNotEmpty ? platformsAbove.first : null;
  }

  bool _shouldJump(Vector2 target, Vector2 current) {
    // Check if we can jump
    if (!_isOnGround || _timeSinceLastJump < _jumpCooldown) {
      return false;
    }

    // Check if we're below the target
    if (current.y > target.y - 100) {
      return false;
    }

    // Check if we're roughly aligned horizontally
    final dx = (target.x - current.x).abs();
    return dx < 100;
  }

  void _jump() {
    body.applyLinearImpulse(Vector2(0, -jumpForce));
    _timeSinceLastJump = 0;
    state = AvatarState.jumping;
  }

  void _updateState() {
    final velocity = body.linearVelocity;

    if (velocity.y > 20) {
      state = AvatarState.falling;
    } else if (velocity.y < -20) {
      state = AvatarState.jumping;
    } else if (velocity.x.abs() > 10) {
      state = AvatarState.walking;
    } else {
      state = AvatarState.idle;
    }
  }

  void _limitSpeed() {
    final velocity = body.linearVelocity;
    if (velocity.x.abs() > maxSpeed) {
      body.linearVelocity = Vector2(
        velocity.x > 0 ? maxSpeed : -maxSpeed,
        velocity.y,
      );
    }
  }

  void setIsKing(bool isKing) {
    _isKing = isKing;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw body (rectangle)
    final bodyRect = Rect.fromCenter(
      center: Offset(0, avatarRadius * 0.5),
      width: avatarRadius * 1.2,
      height: avatarRadius * 1.5,
    );

    final bodyPaint = Paint()
      ..color = _getPlayerColor()
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(5)),
      bodyPaint,
    );

    // Draw head (circle)
    final headPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(0, -avatarRadius * 0.3),
      avatarRadius * 0.6,
      headPaint,
    );

    // Draw player initials or face
    _drawFace(canvas);

    // Draw crown if king
    if (_isKing) {
      drawCrown(canvas);
    }

    // Draw name label
    _drawNameLabel(canvas);
  }

  void _drawFace(Canvas canvas) {
    final initials = _getInitials(player.displayName);

    final textPainter = TextPainter(
      text: TextSpan(
        text: initials,
        style: TextStyle(
          color: Colors.black87,
          fontSize: avatarRadius * 0.5,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        -textPainter.width / 2,
        -avatarRadius * 0.5,
      ),
    );
  }

  @protected
  void drawCrown(Canvas canvas) {
    final crownPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.fill;

    // Simple crown shape
    final path = Path()
      ..moveTo(-10, -avatarRadius - 5)
      ..lineTo(-8, -avatarRadius - 12)
      ..lineTo(-5, -avatarRadius - 8)
      ..lineTo(0, -avatarRadius - 15)
      ..lineTo(5, -avatarRadius - 8)
      ..lineTo(8, -avatarRadius - 12)
      ..lineTo(10, -avatarRadius - 5)
      ..close();

    canvas.drawPath(path, crownPaint);
  }

  void _drawNameLabel(Canvas canvas) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: player.displayName,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.8),
              offset: const Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        -textPainter.width / 2,
        avatarRadius + 5,
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Color _getPlayerColor() {
    // Generate consistent color based on player ID
    final hash = player.userId.hashCode;
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[hash.abs() % colors.length];
  }
}
