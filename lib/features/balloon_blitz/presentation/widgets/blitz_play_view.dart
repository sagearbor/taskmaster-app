import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/services/ar/ar_engine.dart';
import '../../../../core/services/ar/ar_games.dart';
import '../../../../core/services/ar/ar_minigame_controller.dart';

/// The live balloon-popping surface for one phone during a Blitz round.
///
/// It reuses the EXISTING solo gameplay engine verbatim — an [ArMinigameController]
/// driving the [ArEngine] with the shared [ArGameConfig.balloonPop] — and simply
/// taps its [ChangeNotifier] to stream the player's live score out on every pop
/// ([onScoreChanged]) and to signal time-up ([onFinished]). No AR or scoring
/// logic is duplicated here.
///
/// DEVICE-ONLY: the camera + 3D balloon rendering need a physical ARCore phone.
/// The widget builds and the score/finish callbacks are exercised in tests via a
/// fake [ArEngine], but the AR surface itself can only be verified on a device.
class BlitzPlayView extends StatefulWidget {
  /// Called with the new score each time it changes (i.e. on every pop).
  final void Function(int score) onScoreChanged;

  /// Called once when the local round's timer runs out.
  final VoidCallback onFinished;

  const BlitzPlayView({
    super.key,
    required this.onScoreChanged,
    required this.onFinished,
  });

  @override
  State<BlitzPlayView> createState() => _BlitzPlayViewState();
}

class _BlitzPlayViewState extends State<BlitzPlayView> {
  static const ArGameConfig _config = ArGameConfig.balloonPop;

  late final ArEngine _engine;
  late final ArMinigameController _controller;
  int _lastReported = 0;
  bool _finishedNotified = false;

  @override
  void initState() {
    super.initState();
    _engine = sl<ArEngine>();
    _controller = ArMinigameController(engine: _engine, config: _config);
    _controller.addListener(_onControllerChanged);
    _controller.start();
  }

  void _onControllerChanged() {
    final score = _controller.liveScore;
    if (score != _lastReported) {
      _lastReported = score;
      widget.onScoreChanged(score);
    }
    if (_controller.finished && !_finishedNotified) {
      _finishedNotified = true;
      widget.onFinished();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // The platform AR camera view fills the screen.
        _engine.buildView(),

        // Local timer + own score + scanning hint, reacting to the controller.
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.error != null && !_controller.hasLiveObjects) {
              return _CenterCard(
                icon: Icons.error_outline,
                text: "Couldn't start AR.\n${_controller.error}",
              );
            }
            if (!_controller.objectsSpawned && !_controller.finished) {
              return const _CenterCard(
                icon: Icons.center_focus_strong,
                text: 'Point at a well-lit floor or table and move your phone '
                    'slowly to find balloons.',
              );
            }
            return SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _Pill(
                    icon: Icons.timer,
                    label: '${_controller.secondsRemaining}s  ·  '
                        'You ${_controller.liveScore}',
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _CenterCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _CenterCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 10),
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, height: 1.3)),
          ],
        ),
      ),
    );
  }
}
