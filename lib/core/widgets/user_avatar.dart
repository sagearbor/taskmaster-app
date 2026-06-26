import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A circular avatar for a user. Shows the picked [avatarEmoji] when set,
/// otherwise the first initial of [displayName]. The background colour is
/// derived deterministically from the name, so the same person always gets the
/// same colour across the app (app bar, lobby, scoreboard).
class UserAvatar extends StatelessWidget {
  final String displayName;
  final String? avatarEmoji;
  final double radius;

  /// Optional border (used on the violet app bar so the avatar reads clearly).
  final Color? borderColor;

  const UserAvatar({
    super.key,
    required this.displayName,
    this.avatarEmoji,
    this.radius = 20,
    this.borderColor,
  });

  /// Small brand palette to draw from. Kept in sync with [AppTheme].
  static const List<Color> _palette = [
    AppTheme.violet,
    AppTheme.gold,
    AppTheme.coral,
    Color(0xFF14B8A6), // teal
    Color(0xFF3B82F6), // blue
    Color(0xFFEC4899), // pink
    AppTheme.violetDeep,
    Color(0xFF8B5CF6), // light violet
  ];

  static Color colorFor(String name) {
    if (name.isEmpty) return _palette.first;
    // Stable, non-negative hash → palette index.
    var hash = 0;
    for (final unit in name.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return _palette[hash % _palette.length];
  }

  bool get _hasEmoji => avatarEmoji != null && avatarEmoji!.trim().isNotEmpty;

  String get _initial =>
      displayName.trim().isNotEmpty ? displayName.trim()[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    final bg = colorFor(displayName);
    // Choose readable foreground based on background luminance.
    final fg =
        bg.computeLuminance() > 0.55 ? AppTheme.ink : Colors.white;

    return Container(
      decoration: borderColor != null
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderColor!, width: 2),
            )
          : null,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        child: _hasEmoji
            ? Text(
                avatarEmoji!,
                style: TextStyle(fontSize: radius * 1.05),
              )
            : Text(
                _initial,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.bold,
                  fontSize: radius * 0.9,
                ),
              ),
      ),
    );
  }
}
