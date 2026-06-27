import 'practice_game.dart';

/// Game-agnostic lifecycle that drives a [PracticeGame] to completion in solo
/// practice. It knows nothing about any specific game — only the four hooks on
/// [PracticeGame] — so Telephone, Trivia and any future party game reuse it
/// unchanged.
///
/// The rule is intentionally simple and works for every turn-based party game:
/// **after the human acts, fill every pending bot turn until it is the human's
/// turn again (or the game ends).** Because each game reports "the human still
/// owes a submission" via [PracticeGame.needsSubmission], the driver never has
/// to understand rounds, steps or chains — it just stops as soon as control
/// belongs to the human, which is exactly when the UI should take over.
class PracticeDriver<TState> {
  final PracticeGame<TState> game;

  const PracticeDriver(this.game);

  /// Auto-fill any bot turns that come BEFORE the human's first action. A no-op
  /// for games where the human always leads each round (Telephone, Trivia), but
  /// keeps the harness correct for games that don't.
  TState primed(TState state) => _fillBots(state);

  /// Apply the human's [content], then auto-fill every bot that still owes the
  /// current turn so play always lands back on the human (or finishes). Returns
  /// the resulting state for the UI to render.
  TState submitHuman(TState state, String content) {
    final next = game.applySubmission(state, game.humanUid, content);
    return _fillBots(next);
  }

  /// Keep submitting for pending bots while it is NOT the human's turn and the
  /// game is not done. Stops the instant the human owes a submission (their
  /// turn) or no bot is pending — guaranteeing termination.
  TState _fillBots(TState state) {
    var current = state;
    while (!game.isDone(current) &&
        !game.needsSubmission(current, game.humanUid)) {
      final bot = _pendingBot(current);
      if (bot == null) break;
      current =
          game.applySubmission(current, bot, game.botContent(current, bot));
    }
    return current;
  }

  /// The first bot still owing a submission for the current turn, or null.
  String? _pendingBot(TState state) {
    for (final uid in game.botUids) {
      if (game.needsSubmission(state, uid)) return uid;
    }
    return null;
  }
}
