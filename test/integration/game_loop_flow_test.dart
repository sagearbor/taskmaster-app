import 'package:flutter_test/flutter_test.dart';
import 'package:taskcaster_app/core/di/service_locator.dart';
import 'package:taskcaster_app/core/models/game.dart';
import 'package:taskcaster_app/core/models/player.dart';
import 'package:taskcaster_app/core/models/submission.dart';
import 'package:taskcaster_app/core/models/task.dart';
import 'package:taskcaster_app/features/games/domain/repositories/game_repository.dart';

/// End-to-end flow test for the core game loop, driven through the real
/// [GameRepository] + BLoC logic against the mock data source. Runs headlessly
/// via `flutter test` (no device needed, unlike package:integration_test).
///
/// Covers: create game -> set up players & tasks -> start -> judge -> final
/// scoreboard ordering. Exercises Game model serialization round-tripping
/// through the mock data layer and the score-accumulation logic in
/// GameRepositoryImpl.judgeSubmission / startGame.
void main() {
  group('Game loop flow (mock services)', () {
    late GameRepository repo;

    setUp(() async {
      await ServiceLocator.init(useMockServices: true);
      repo = sl<GameRepository>();
    });

    tearDown(() async {
      await sl.reset();
    });

    test('create -> start -> judge -> scoreboard produces correct standings',
        () async {
      const creatorId = 'alice';
      const challengerId = 'bob';

      // 1. Create a game (starts in the lobby with the creator as sole player).
      final gameId = await repo.createGame('Test Party', creatorId, creatorId);
      expect(gameId, isNotEmpty);

      final created = await repo.getGameStream(gameId).first;
      expect(created, isNotNull);
      expect(created!.status, GameStatus.lobby);
      expect(created.players, hasLength(1));

      // 2a. A second player joins via the invite code.
      await repo.joinGame(created.inviteCode, challengerId, 'Bob');
      final joined = await repo.getGameStream(gameId).first;
      expect(joined!.players.map((p) => p.userId),
          containsAll([creatorId, challengerId]));

      // 2b. Add a task to the game.
      await repo.addTasksToGame(gameId, [
        const Task(
          id: 'task-1',
          title: 'Make the best paper airplane',
          description: 'Most aerodynamic wins',
          taskType: TaskType.video,
          submissions: [],
        ),
      ]);
      final withTask = await repo.getGameStream(gameId).first;
      expect(withTask!.tasks.single.id, 'task-1');

      // 3. Start the game — initializes per-player task statuses.
      await repo.startGame(gameId);
      final started = await repo.getGameStream(gameId).first;
      expect(started!.status, GameStatus.inProgress);
      expect(started.tasks.single.playerStatuses.keys,
          containsAll([creatorId, challengerId]));

      // 4a. The challenger submits a video answer for task 0.
      await repo.submitTaskAnswer(
        gameId,
        'task-1',
        Submission(
          id: 'sub-1',
          userId: challengerId,
          videoUrl: 'https://youtu.be/example',
          score: 0,
          isJudged: false,
          submittedAt: DateTime.now(),
        ),
      );
      final submitted = await repo.getGameStream(gameId).first;
      expect(submitted!.tasks.single.submissions, hasLength(1));

      // 4b. Judge: award points on task 0.
      await repo.judgeSubmission(gameId, 0, challengerId, 5);
      await repo.judgeSubmission(gameId, 0, creatorId, 3);

      final judged = await repo.getGameStream(gameId).first;
      final bob = judged!.players.firstWhere((p) => p.userId == challengerId);
      final alice = judged.players.firstWhere((p) => p.userId == creatorId);
      expect(bob.totalScore, 5);
      expect(alice.totalScore, 3);

      // 5. Complete the game and verify the scoreboard ordering.
      await repo.updateGame(gameId, judged.copyWith(status: GameStatus.completed));
      final completed = await repo.getGameStream(gameId).first;
      expect(completed!.status, GameStatus.completed);

      final standings = List<Player>.from(completed.players)
        ..sort((a, b) => b.totalScore.compareTo(a.totalScore));
      expect(standings.first.userId, challengerId); // Bob (5) wins
      expect(standings.last.userId, creatorId); // Alice (3) second
    });

    test(
        'judging every player completes the task + game and stamps submissions',
        () async {
      const creatorId = 'alice';
      const challengerId = 'bob';

      final gameId = await repo.createGame('Finale', creatorId, creatorId);
      final created = await repo.getGameStream(gameId).first;
      await repo.joinGame(created!.inviteCode, challengerId, 'Bob');
      await repo.addTasksToGame(gameId, [
        const Task(
          id: 'task-1',
          title: 'Only task',
          description: 'Single task game',
          taskType: TaskType.video,
          submissions: [],
        ),
      ]);
      await repo.startGame(gameId);

      // Both players submit.
      for (final id in [creatorId, challengerId]) {
        await repo.submitTaskAnswer(
          gameId,
          'task-1',
          Submission(
            id: 'sub-$id',
            userId: id,
            videoUrl: 'https://example.com/$id',
            score: 0,
            isJudged: false,
            submittedAt: DateTime.now(),
          ),
        );
      }

      // Once everyone has submitted, the task is ready to judge.
      final readyGame = await repo.getGameStream(gameId).first;
      expect(readyGame!.tasks.single.status, TaskStatus.ready_to_judge);

      // Judge both players.
      await repo.judgeSubmission(gameId, 0, challengerId, 5);
      await repo.judgeSubmission(gameId, 0, creatorId, 3);

      final done = await repo.getGameStream(gameId).first;
      final task = done!.tasks.single;

      // Submissions carry the awarded scores and are flagged judged.
      final bobSub = task.submissions.firstWhere((s) => s.userId == challengerId);
      final aliceSub = task.submissions.firstWhere((s) => s.userId == creatorId);
      expect(bobSub.score, 5);
      expect(bobSub.isJudged, isTrue);
      expect(aliceSub.score, 3);
      expect(aliceSub.isJudged, isTrue);

      // Task completes, and with all tasks complete the game completes too.
      expect(task.status, TaskStatus.completed);
      expect(task.allPlayersJudged, isTrue);
      expect(done.status, GameStatus.completed);

      // Player totals reflect the awarded scores.
      expect(done.players.firstWhere((p) => p.userId == challengerId).totalScore, 5);
      expect(done.players.firstWhere((p) => p.userId == creatorId).totalScore, 3);
    });

    test('starting a game with fewer than 2 players is rejected', () async {
      final gameId = await repo.createGame('Solo', 'alice', 'alice');
      final game = await repo.getGameStream(gameId).first;
      // Give it a task but leave only the single creator as a player.
      await repo.updateGame(
        gameId,
        game!.copyWith(tasks: [
          const Task(
            id: 't',
            title: 'x',
            description: 'y',
            taskType: TaskType.video,
            submissions: [],
          ),
        ]),
      );
      expect(() => repo.startGame(gameId), throwsA(isA<Exception>()));
    });
  });
}
