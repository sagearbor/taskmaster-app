import 'dart:convert';
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

/// One pen stroke. Points are stored NORMALISED to 0..1 of the canvas so a
/// drawing renders identically at any size / on any device.
class DrawingStroke {
  final int color;
  final List<Offset> points;

  DrawingStroke(this.color, this.points);

  Map<String, dynamic> toJson() => {
        'c': color,
        'p': [for (final pt in points) ...[pt.dx, pt.dy]],
      };

  factory DrawingStroke.fromJson(Map<String, dynamic> map) {
    final flat = (map['p'] as List).cast<num>();
    final pts = <Offset>[];
    for (var i = 0; i + 1 < flat.length; i += 2) {
      pts.add(Offset(flat[i].toDouble(), flat[i + 1].toDouble()));
    }
    return DrawingStroke((map['c'] as num).toInt(), pts);
  }
}

/// Decode the JSON produced by [DrawingController.toJson]. Tolerant of empty /
/// malformed input (returns an empty list) so a bad document never crashes the
/// reveal.
List<DrawingStroke> parseStrokes(String json) {
  if (json.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(json);
    if (decoded is! List) return const [];
    return decoded
        .map((e) => DrawingStroke.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  } catch (_) {
    return const [];
  }
}

/// Holds the in-progress drawing for [DrawingCanvas].
class DrawingController extends ChangeNotifier {
  final List<DrawingStroke> _strokes = [];
  Color color = Colors.black;

  List<DrawingStroke> get strokes => List.unmodifiable(_strokes);

  bool get isEmpty => _strokes.every((s) => s.points.isEmpty);

  void selectColor(Color c) {
    color = c;
    notifyListeners();
  }

  void startStroke(Offset normalized) {
    _strokes.add(DrawingStroke(color.value, [normalized]));
    notifyListeners();
  }

  void appendPoint(Offset normalized) {
    if (_strokes.isNotEmpty) {
      _strokes.last.points.add(normalized);
      notifyListeners();
    }
  }

  void undo() {
    if (_strokes.isNotEmpty) {
      _strokes.removeLast();
      notifyListeners();
    }
  }

  void clear() {
    _strokes.clear();
    notifyListeners();
  }

  String toJson() => jsonEncode([for (final s in _strokes) s.toJson()]);
}

const List<Color> kPenColors = [
  Colors.black,
  Color(0xFFE53935), // red
  Color(0xFF1E88E5), // blue
  Color(0xFF43A047), // green
  Color(0xFFFB8C00), // orange
  Color(0xFF8E24AA), // purple
];

/// An editable freehand canvas. Square, normalised, web-friendly (uses pan
/// gestures — no platform-specific pointer APIs).
class DrawingCanvas extends StatelessWidget {
  final DrawingController controller;

  const DrawingCanvas({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final side = constraints.maxWidth;
              Offset normalize(Offset local) => Offset(
                    (local.dx / side).clamp(0.0, 1.0),
                    (local.dy / side).clamp(0.0, 1.0),
                  );
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black26, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (d) =>
                      controller.startStroke(normalize(d.localPosition)),
                  onPanUpdate: (d) =>
                      controller.appendPoint(normalize(d.localPosition)),
                  child: AnimatedBuilder(
                    animation: controller,
                    builder: (context, _) => CustomPaint(
                      painter: _StrokePainter(controller.strokes),
                      size: Size(side, side),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _Toolbar(controller: controller),
      ],
    );
  }
}

class _Toolbar extends StatelessWidget {
  final DrawingController controller;
  const _Toolbar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Row(
        children: [
          for (final c in kPenColors)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => controller.selectColor(c),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: controller.color == c
                          ? Colors.amber
                          : Colors.black26,
                      width: controller.color == c ? 3 : 1,
                    ),
                  ),
                ),
              ),
            ),
          const Spacer(),
          IconButton(
            tooltip: 'Undo',
            onPressed: controller.undo,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: 'Clear',
            onPressed: controller.clear,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

/// Read-only renderer for a stored drawing (used by the guess step and the
/// reveal). Always square.
class DrawingView extends StatelessWidget {
  final String json;
  final double? size;

  const DrawingView({super.key, required this.json, this.size});

  @override
  Widget build(BuildContext context) {
    final strokes = parseStrokes(json);
    final canvas = AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: CustomPaint(
          painter: _StrokePainter(strokes),
          child: const SizedBox.expand(),
        ),
      ),
    );
    if (size != null) {
      return SizedBox(width: size, height: size, child: canvas);
    }
    return canvas;
  }
}

class _StrokePainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  _StrokePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = Color(stroke.color)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      Offset denorm(Offset p) => Offset(p.dx * size.width, p.dy * size.height);

      if (stroke.points.length == 1) {
        // A single tap → a dot.
        canvas.drawPoints(
          PointMode.points,
          [denorm(stroke.points.first)],
          paint..strokeCap = StrokeCap.round,
        );
        continue;
      }
      final path = Path()..moveTo(
          denorm(stroke.points.first).dx, denorm(stroke.points.first).dy);
      for (var i = 1; i < stroke.points.length; i++) {
        final p = denorm(stroke.points[i]);
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_StrokePainter oldDelegate) =>
      oldDelegate.strokes != strokes;
}
