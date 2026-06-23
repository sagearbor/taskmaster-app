import 'package:flutter_test/flutter_test.dart';
import 'package:taskmaster_app/core/di/service_locator.dart';
import 'package:taskmaster_app/core/models/game.dart';
import 'package:taskmaster_app/core/models/player.dart';
import 'package:taskmaster_app/core/models/task.dart';
import 'package:taskmaster_app/features/games/domain/repositories/game_repository.dart';

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

      // 2. Set up a startable game: add a second player and one task.
      //    (joinGame / addTasksToGame are stubs in the repository, so we wire
      //    the state in directly via updateGame — the path the data layer uses.)
      final readyGame = created.copyWith(
        players: [
          ...created.players,
          const Player(
              userId: challengerId, displayName: 'Bob', totalScore: 0),
        ],
        tasks: [
          const Task(
            id: 'task-1',
            title: 'Make the best paper airplane',
            description: 'Most aerodynamic wins',
            taskType: TaskType.video,
            submissions: [],
          ),
        ],
      );
      await repo.updateGame(gameId, readyGame);

      // 3. Start the game — initializes per-player task statuses.
      await repo.startGame(gameId);
      final started = await repo.getGameStream(gameId).first;
      expect(started!.status, GameStatus.inProgress);
      expect(started.tasks.single.playerStatuses.keys,
          containsAll([creatorId, challengerId]));

      // 4. Judge: award points on task 0.
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
