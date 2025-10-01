import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../../../core/models/game.dart' as app_game;
import '../../game/king_of_mountain_game.dart';

/// Overlay widget that shows the King of the Mountain avatar game
/// Displays on top of the game lobby with semi-transparent background
class AvatarGameOverlay extends StatefulWidget {
  final app_game.Game game;
  final Widget child;

  const AvatarGameOverlay({
    super.key,
    required this.game,
    required this.child,
  });

  @override
  State<AvatarGameOverlay> createState() => _AvatarGameOverlayState();
}

class _AvatarGameOverlayState extends State<AvatarGameOverlay> {
  late KingOfMountainGame _avatarGame;
  bool _showAvatars = true;

  @override
  void initState() {
    super.initState();
    _avatarGame = KingOfMountainGame(players: widget.game.players);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main lobby UI
        widget.child,

        // Avatar game overlay (only show in lobby status)
        if (_showAvatars && widget.game.isInLobby)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: MediaQuery.of(context).size.width > 600 ? 400 : MediaQuery.of(context).size.width,
            child: Container(
              color: Colors.transparent,
              child: GameWidget(
                game: _avatarGame,
                overlayBuilderMap: {
                  'controls': (context, game) => _buildControls(context),
                },
                initialActiveOverlays: const ['controls'],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildControls(BuildContext context) {
    return Positioned(
      top: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  _showAvatars ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _showAvatars = !_showAvatars;
                  });
                },
                tooltip: _showAvatars ? 'Hide avatars' : 'Show avatars',
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  'King of Mountain',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _avatarGame.pauseEngine();
    super.dispose();
  }
}
