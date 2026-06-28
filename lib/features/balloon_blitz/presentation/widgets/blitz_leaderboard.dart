import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/blitz_session.dart';

/// The live leaderboard shown during and after a round. Ranks players highest
/// score first (via [BlitzSession.leaderboard]) and highlights "you" so a player
/// can find themselves at a glance. Used both as a translucent in-play overlay
/// and as the full-screen results list.
class BlitzLeaderboard extends StatelessWidget {
  final BlitzSession session;

  /// This device's player id, highlighted in the list.
  final String selfId;

  /// Compact, translucent styling for overlaying the live AR camera view.
  final bool overlay;

  const BlitzLeaderboard({
    super.key,
    required this.session,
    required this.selfId,
    this.overlay = false,
  });

  @override
  Widget build(BuildContext context) {
    final ranked = session.leaderboard;
    final children = <Widget>[];
    for (var i = 0; i < ranked.length; i++) {
      children.add(_BlitzRow(
        rank: i + 1,
        player: ranked[i],
        isSelf: ranked[i].id == selfId,
        overlay: overlay,
      ));
    }

    final list = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );

    if (!overlay) return list;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: list,
    );
  }
}

class _BlitzRow extends StatelessWidget {
  final int rank;
  final BlitzPlayer player;
  final bool isSelf;
  final bool overlay;

  const _BlitzRow({
    required this.rank,
    required this.player,
    required this.isSelf,
    required this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medal = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '$rank',
    };
    final onColor = overlay ? Colors.white : theme.colorScheme.onSurface;
    final nameStyle = TextStyle(
      color: onColor,
      fontWeight: isSelf ? FontWeight.w800 : FontWeight.w600,
      fontSize: overlay ? 14 : 16,
    );

    final highlight = isSelf
        ? (overlay
            ? AppTheme.gold.withOpacity(0.25)
            : AppTheme.violetSoft)
        : Colors.transparent;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(medal,
                style: TextStyle(fontSize: overlay ? 14 : 16, color: onColor)),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    player.name,
                    overflow: TextOverflow.ellipsis,
                    style: nameStyle,
                  ),
                ),
                if (player.isHost) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.wifi_tethering,
                      size: overlay ? 13 : 15, color: AppTheme.gold),
                ],
                if (isSelf) ...[
                  const SizedBox(width: 6),
                  Text('(you)',
                      style: TextStyle(
                          color: onColor.withOpacity(0.8),
                          fontSize: overlay ? 11 : 12)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${player.liveScore}',
            style: TextStyle(
              color: onColor,
              fontWeight: FontWeight.w800,
              fontSize: overlay ? 15 : 18,
            ),
          ),
        ],
      ),
    );
  }
}
