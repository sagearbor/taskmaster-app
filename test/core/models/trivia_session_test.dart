import 'package:flutter_test/flutter_test.dart';
import 'package:taskcaster_app/core/models/session_mode.dart';
import 'package:taskcaster_app/core/models/trivia_questions.dart';
import 'package:taskcaster_app/core/models/trivia_session.dart';

// Fixed question line-up with known correct indexes so scoring is deterministic.
//   geo1 -> 'What is the capital of France?'  correct index 2 (Paris)
//   sci3 -> 'How many legs does a spider have?' correct index 1 (8)
//   gen3 -> 'How many sides does a hexagon have?' correct index 1 (6)
const _qids = ['geo1', 'sci3', 'gen3'];

int _correctOf(String id) => triviaQuestionById(id)!.correctIndex;

/// A 2-player session moved into play on question 0.
TriviaSession startedTwoPlayer({List<String> questionIds = _qids}) {
  return TriviaSession.create(
    id: 's1',
    gameName: 'Test',
    inviteCode: 'ABC123',
    creatorUid: 'p0',
    creatorName: 'P0',
    questionIds: questionIds,
    createdAt: DateTime(2026, 1, 1),
  ).withPlayerJoined('p1', 'P1').started();
}

void main() {
  group('TriviaSession — defaults & serialization', () {
    test('new session is a party-mode lobby with just the creator', () {
      final s = TriviaSession.create(
        id: 's1',
        gameName: 'Quiz Night',
        inviteCode: 'ABC123',
        creatorUid: 'p0',
        creatorName: 'P0',
        questionIds: _qids,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(s.phase, TriviaPhase.lobby);
      expect(s.mode, SessionMode.party);
      expect(s.playerCount, 1);
      expect(s.players.single.uid, 'p0');
      expect(s.players.single.score, 0);
      expect(s.totalQuestions, 3);
      expect(s.currentQuestionIndex, 0);
      expect(s.buzzes, isEmpty);
    });

    test('toMap/fromMap round-trips all state including scores & buzzes', () {
      var s = startedTwoPlayer();
      s = s.withBuzz('p0', _correctOf('geo1'), 100); // correct, scores
      // p1 not buzzed yet -> still playing
      expect(s.isPlaying, isTrue);

      final restored = TriviaSession.fromMap(s.toMap());
      expect(restored, equals(s));
      expect(restored.buzzes.single.uid, 'p0');
      expect(restored.buzzes.single.atMillis, 100);
    });

    test('currentQuestion resolves from the bundled bank', () {
      final s = startedTwoPlayer();
      expect(s.currentQuestion?.id, 'geo1');
      expect(s.currentQuestion?.correctAnswer, 'Paris');
    });
  });

  group('TriviaSession — lobby & start', () {
    test('withPlayerJoined adds a player and is idempotent', () {
      var s = TriviaSession.create(
        id: 's1',
        gameName: 'T',
        inviteCode: 'AAA111',
        creatorUid: 'p0',
        creatorName: 'P0',
        questionIds: _qids,
      );
      s = s.withPlayerJoined('p1', 'P1');
      expect(s.playerCount, 2);
      // Re-joining the same uid changes nothing.
      final again = s.withPlayerJoined('p1', 'P1 again');
      expect(again, equals(s));
    });

    test('cannot join once the game has started', () {
      final s = startedTwoPlayer();
      final after = s.withPlayerJoined('p2', 'Late');
      expect(after.playerCount, 2);
      expect(after, equals(s));
    });

    test('started() moves to playing, resets scores, clears buzzes', () {
      final s = startedTwoPlayer();
      expect(s.isPlaying, isTrue);
      expect(s.currentQuestionIndex, 0);
      expect(s.players.every((p) => p.score == 0), isTrue);
    });

    test('started() throws with no players', () {
      final empty = TriviaSession(
        id: 's1',
        gameName: 'T',
        mode: SessionMode.party,
        inviteCode: 'AAA111',
        creatorUid: 'p0',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        players: const [],
        phase: TriviaPhase.lobby,
        questionIds: _qids,
        currentQuestionIndex: 0,
        buzzes: const [],
      );
      expect(empty.started, throwsStateError);
    });

    test('started() throws with no questions configured', () {
      final s = TriviaSession.create(
        id: 's1',
        gameName: 'T',
        inviteCode: 'AAA111',
        creatorUid: 'p0',
        creatorName: 'P0',
        questionIds: const [],
      );
      expect(s.started, throwsStateError);
    });
  });

  group('TriviaSession — buzzing', () {
    test('records a buzz and locks it (second buzz ignored)', () {
      var s = startedTwoPlayer();
      s = s.withBuzz('p0', 0, 100);
      expect(s.hasBuzzed('p0'), isTrue);
      expect(s.buzzes.length, 1);
      // A second buzz from p0 is ignored — answer is locked.
      final locked = s.withBuzz('p0', 3, 200);
      expect(locked, equals(s));
      expect(locked.buzzes.single.choiceIndex, 0);
    });

    test('ignores buzzes from non-players and outside playing phase', () {
      var s = startedTwoPlayer();
      expect(s.withBuzz('ghost', 0, 100), equals(s));

      // Force into reveal and confirm buzzing is a no-op.
      s = s.revealed();
      expect(s.isRevealing, isTrue);
      expect(s.withBuzz('p1', 0, 100), equals(s));
    });

    test('auto-reveals once every player has buzzed', () {
      var s = startedTwoPlayer();
      s = s.withBuzz('p0', _correctOf('geo1'), 100);
      expect(s.isPlaying, isTrue);
      s = s.withBuzz('p1', 0, 150);
      expect(s.isRevealing, isTrue); // all buzzed -> reveal
    });
  });

  group('TriviaSession — first-correct selection', () {
    test('winner is the earliest CORRECT buzz, by atMillis not arrival order',
        () {
      var s = startedTwoPlayer();
      final correct = _correctOf('geo1');
      // p1 buzzes (correct) at t=200 but is recorded first;
      // p0 buzzes (correct) at t=100 recorded second.
      s = s.withBuzz('p1', correct, 200);
      s = s.withBuzz('p0', correct, 100); // all buzzed -> reveal
      expect(s.isRevealing, isTrue);
      expect(s.winnerUid, 'p0'); // earliest timestamp wins
    });

    test('an earlier WRONG buzz does not steal the win', () {
      var s = startedTwoPlayer();
      final correct = _correctOf('geo1');
      s = s.withBuzz('p1', 0, 100); // wrong, but earliest
      s = s.withBuzz('p0', correct, 200); // correct, later
      expect(s.winnerUid, 'p0');
    });

    test('nobody scores if no buzz is correct', () {
      var s = startedTwoPlayer();
      s = s.withBuzz('p0', 0, 100);
      s = s.withBuzz('p1', 3, 150);
      expect(s.isRevealing, isTrue);
      expect(s.winnerUid, isNull);
      expect(s.players.every((p) => p.score == 0), isTrue);
    });
  });

  group('TriviaSession — scoring', () {
    test('fastest correct (first overall) earns base + speed bonus', () {
      var s = startedTwoPlayer(); // base 100, speedBonus 50
      final correct = _correctOf('geo1');
      s = s.withBuzz('p0', correct, 100); // first overall AND correct
      s = s.withBuzz('p1', 0, 200);
      final p0 = s.players.firstWhere((p) => p.uid == 'p0');
      expect(p0.score, 150);
    });

    test('correct but not first-to-buzz earns base only (no speed bonus)', () {
      var s = startedTwoPlayer();
      final correct = _correctOf('geo1');
      s = s.withBuzz('p1', 0, 100); // wrong, but buzzed first overall
      s = s.withBuzz('p0', correct, 200); // correct winner, not first overall
      final p0 = s.players.firstWhere((p) => p.uid == 'p0');
      expect(p0.score, 100);
    });

    test('revealed() scores once and is not double-applied', () {
      var s = startedTwoPlayer();
      final correct = _correctOf('geo1');
      s = s.withBuzz('p0', correct, 100); // only p0 buzzes
      s = s.revealed(); // host reveals early, scores p0 (first overall): 150
      final once = s.players.firstWhere((p) => p.uid == 'p0').score;
      expect(once, 150);
      // Calling revealed again in reveal phase is a no-op.
      final twice = s.revealed().players.firstWhere((p) => p.uid == 'p0').score;
      expect(twice, 150);
    });
  });

  group('TriviaSession — advance & end of game', () {
    test('advanceQuestion moves to the next question and clears buzzes', () {
      var s = startedTwoPlayer();
      s = s.withBuzz('p0', _correctOf('geo1'), 100);
      s = s.withBuzz('p1', 0, 150); // -> reveal
      s = s.advanceQuestion();
      expect(s.isPlaying, isTrue);
      expect(s.currentQuestionIndex, 1);
      expect(s.currentQuestion?.id, 'sci3');
      expect(s.buzzes, isEmpty);
      expect(s.hasBuzzed('p0'), isFalse);
    });

    test('advanceQuestion after the last question ends the game', () {
      var s = startedTwoPlayer(questionIds: ['geo1']); // single question
      s = s.withBuzz('p0', _correctOf('geo1'), 100);
      s = s.withBuzz('p1', 0, 150); // -> reveal
      expect(s.isLastQuestion, isTrue);
      s = s.advanceQuestion();
      expect(s.isDone, isTrue);
      expect(s.buzzes, isEmpty);
    });

    test('advanceQuestion is a no-op outside reveal', () {
      final s = startedTwoPlayer();
      expect(s.advanceQuestion(), equals(s));
    });

    test('scores accumulate across a full multi-question game', () {
      var s = startedTwoPlayer(); // geo1, sci3, gen3
      // Q1 geo1: p0 fastest correct -> +150
      s = s.withBuzz('p0', _correctOf('geo1'), 100);
      s = s.withBuzz('p1', 0, 200);
      s = s.advanceQuestion();
      // Q2 sci3: p1 fastest correct -> +150
      s = s.withBuzz('p1', _correctOf('sci3'), 100);
      s = s.withBuzz('p0', 0, 200);
      s = s.advanceQuestion();
      // Q3 gen3: p0 correct but p1 buzzed first (wrong) -> p0 +100
      s = s.withBuzz('p1', 0, 100);
      s = s.withBuzz('p0', _correctOf('gen3'), 200);
      s = s.advanceQuestion();

      expect(s.isDone, isTrue);
      final p0 = s.players.firstWhere((p) => p.uid == 'p0').score;
      final p1 = s.players.firstWhere((p) => p.uid == 'p1').score;
      expect(p0, 250); // 150 + 100
      expect(p1, 150);

      // Scoreboard is highest-first.
      expect(s.scoreboard.first.uid, 'p0');
      expect(s.scoreboard.last.uid, 'p1');
    });
  });
}
