import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

/// Platform that avatars can stand on and jump to
class PlatformComponent extends BodyComponent {
  final Vector2 position;
  final double width;
  final double height;
  final bool isGround;
  final bool isPeak;

  PlatformComponent({
    required this.position,
    required this.width,
    required this.height,
    this.isGround = false,
    this.isPeak = false,
  });

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      position: position,
      type: BodyType.static,
    );

    final shape = PolygonShape()
      ..setAsBox(
        width / 2,
        height / 2,
        Vector2.zero(),
        0,
      );

    final fixtureDef = FixtureDef(shape)
      ..friction = 0.8 // High friction so avatars don't slide
      ..restitution = 0.0; // No bounce

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()
      ..color = isPeak
          ? Colors.amber.withOpacity(0.8) // Gold for peak
          : isGround
              ? Colors.brown.withOpacity(0.6)
              : Colors.grey.withOpacity(0.7);

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset.zero,
        width: width,
        height: height,
      ),
      paint,
    );

    // Draw decorative lines
    if (isPeak) {
      final borderPaint = Paint()
        ..color = Colors.yellow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: width,
          height: height,
        ),
        borderPaint,
      );
    }
  }
}
