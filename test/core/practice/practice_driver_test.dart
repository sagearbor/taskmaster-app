import 'package:flutter_test/flutter_test.dart';
import 'package:taskcaster_app/core/practice/practice_driver.dart';
import 'package:taskcaster_app/core/practice/practice_game.dart';

/// A tiny, made-up party game used ONLY to prove the generic driver is
/// game-agnostic (it stands in for "Trivia" / any future adopter). Every round,
/// each player submits one answer; after [rounds] rounds the game is done.
class _RoundGameState {
  final int rounds;
  final List<String> players;
  final int round;
  // round -> set of player ids that have answered this round.
  final List<Set<String>> answered;
  // collected answers, in submission order, as "round:uid=content".
  final List<String> log;

  const _RoundGameState({
    required this.rounds,
    required this.players,
    required this.round,
    required this.answered,
    required this.log,
  });

  factory _RoundGameState.start(List<String> players, int rounds) =>
      _RoundGameState(
        rounds: rounds,
        players: players,
        round: 0,
        answered: List.generate(rounds, (_) => <String>{}),
        log: const [],
      );

  bool get done => round >= rounds;
}

class _RoundGame extends PracticeGame<_RoundGameState> {
  @override
  final String humanUid;
  @override
  final List<String> botUids;

  _RoundGame({required this.humanUid, required this.botUids});

  @override
  bool isDone(_RoundGameState s) => s.done;

  @override
  bool needsSubmission(_RoundGameState s, String uid) =>
      !s.done && !s.answered[s.round].contains(uid);

  @override
  _RoundGameState applySubmission(_RoundGameState s, String uid, String content) {
    if (s.done || s.answered[s.round].contains(uid)) return s;
    final answered = [for (final set in s.answered) {...set}];
    answered[s.round].add(uid);
    final log = [...s.log, '${s.round}:$uid=$content'];
    final everyone = answered[s.round].length >= s.players.length;
    return _RoundGameState(
      rounds: s.rounds,
      players: s.players,
      round: everyone ? s.round + 1 : s.round,
      answered: answered,
      log: log,
    );
  }

  @override
  String botContent(_RoundGameState s, String botUid) => 'bot-answer';
}

void main() {
  group('PracticeDriver (generic harness)', () {
    test('after the human submits, bots auto-fill until the human is up again',
        () {
      final game = _RoundGame(humanUid: 'me', botUids: const ['b1', 'b2']);
      final driver = PracticeDriver<_RoundGameState>(game);

      var state = driver.primed(
        _RoundGameState.start(const ['me', 'b1', 'b2'], 3),
      );

      // Round 0: the human is up, and priming did NOT submit for any bot ahead
      // of them (no answers logged yet). Bots remain pending — they only move
      // once it stops being the human's turn.
      expect(game.needsSubmission(state, 'me'), isTrue);
      expect(state.log, isEmpty,
          reason: 'priming must not run bots ahead of the human');
      expect(game.needsSubmission(state, 'b1'), isTrue);

      state = driver.submitHuman(state, 'human-0');

      // Control is handed back to the human on the NEXT round, with both bots
      // already filled for round 0.
      expect(state.round, 1);
      expect(game.needsSubmission(state, 'me'), isTrue);
      expect(game.needsSubmission(state, 'b1'), isTrue,
          reason: 'a fresh round means bots are pending again until their turn');
    });

    test('driving every human turn runs the game to completion', () {
      final game = _RoundGame(humanUid: 'me', botUids: const ['b1', 'b2']);
      final driver = PracticeDriver<_RoundGameState>(game);

      var state = driver.primed(
        _RoundGameState.start(const ['me', 'b1', 'b2'], 3),
      );

      var humanTurns = 0;
      while (!game.isDone(state)) {
        expect(game.needsSubmission(state, 'me'), isTrue,
            reason: 'the driver always stops on the human turn');
        state = driver.submitHuman(state, 'human-$humanTurns');
        humanTurns++;
        expect(humanTurns, lessThanOrEqualTo(3), reason: 'must terminate');
      }

      expect(state.done, isTrue);
      expect(humanTurns, 3, reason: 'one human action per round');
      // 3 rounds x 3 players = 9 submissions, all recorded.
      expect(state.log, hasLength(9));
    });
  });
}
