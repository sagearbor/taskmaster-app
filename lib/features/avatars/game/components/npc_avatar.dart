import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import '../../../../core/models/player.dart';
import 'platform_component.dart';
import 'player_avatar.dart';

/// NPC avatar with emoji face - fills empty slots when there aren't enough players
class NPCAvatar extends PlayerAvatar {
  final String emoji;

  NPCAvatar({
    required this.emoji,
    required String name,
    required Vector2 startPosition,
    required List<PlatformComponent> platforms,
  }) : super(
          player: Player(
            userId: 'npc_${Random().nextInt(10000)}',
            displayName: name,
            totalScore: 0,
          ),
          startPosition: startPosition,
          platforms: platforms,
        );

  @override
  void render(Canvas canvas) {
    // Draw body (same as PlayerAvatar)
    final bodyRect = Rect.fromCenter(
      center: Offset(0, avatarRadius * 0.5),
      width: avatarRadius * 1.2,
      height: avatarRadius * 1.5,
    );

    final bodyPaint = Paint()
      ..color = _getNPCColor()
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

    // Draw emoji face instead of initials
    _drawEmojiFace(canvas);

    // Draw crown if king
    if (isKing) {
      drawCrown(canvas);
    }

    // Draw name label
    _drawNPCNameLabel(canvas);
  }

  void _drawEmojiFace(Canvas canvas) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(
          fontSize: avatarRadius * 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        -textPainter.width / 2,
        -avatarRadius * 0.6,
      ),
    );
  }

  void _drawNPCNameLabel(Canvas canvas) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: player.displayName,
        style: TextStyle(
          color: Colors.white70,
          fontSize: 9,
          fontStyle: FontStyle.italic,
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

  Color _getNPCColor() {
    // Use gray tones for NPCs to distinguish from real players
    final grayShades = [
      Colors.grey[600]!,
      Colors.grey[700]!,
      Colors.blueGrey[600]!,
      Colors.blueGrey[700]!,
    ];

    final hash = emoji.hashCode;
    return grayShades[hash.abs() % grayShades.length];
  }

  // NPCs might be slightly less aggressive in their climbing
  @override
  void updateAI(double dt) {
    // Add some randomness to NPC behavior
    if (Random().nextDouble() < 0.8) {
      // 80% of the time, act normally
      super.updateAI(dt);
    } else {
      // 20% of the time, idle or wander
      if (Random().nextDouble() < 0.3) {
        final direction = Random().nextBool() ? 1.0 : -1.0;
        body.applyForce(Vector2(moveSpeed * 0.5 * direction, 0));
      }
    }
  }
}
