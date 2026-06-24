import 'package:flutter_test/flutter_test.dart';
import 'package:taskmaster_app/core/models/game.dart';
import 'package:taskmaster_app/core/models/game_settings.dart';
import 'package:taskmaster_app/core/models/player.dart';
import 'package:taskmaster_app/core/models/task.dart';
import 'package:taskmaster_app/features/games/data/datasources/mock_game_data_source.dart';
import 'package:taskmaster_app/features/games/data/repositories/game_repository_impl.dart';

void main() {
  group('Public games', () {
    late GameRepositoryImpl repo;

    setUp(() => repo = GameRepositoryImpl(MockGameDataSource()));

    test('getPublicGamesStream returns only games marked public', () async {
      final games = await repo.getPublicGamesStream().first;

      expect(games, isNotEmpty);
      expect(games.every((g) => g.isPublic), isTrue);
      expect(
        games.map((g) => g.gameName),
        containsAll(['Weekend Warriors', 'Epic Adventure']),
      );
    });

    test('cloneGame creates a private game owned by the cloner with fresh copies of the tasks',
        () async {
      final template = (await repo.getPublicGamesStream().first)
          .firstWhere((g) => g.gameName == 'Epic Adventure');

      final newId = await repo.cloneGame(template, 'alice', 'Alice');
      final cloned = await repo.getGameStream(newId).first;

      expect(cloned, isNotNull);
      expect(cloned!.creatorId, 'alice');
      expect(cloned.isPublic, isFalse, reason: 'a clone should be private');
      expect(cloned.status, GameStatus.lobby);
      expect(cloned.tasks.length, template.tasks.length);
      expect(
        cloned.tasks.map((t) => t.title),
        containsAll(template.tasks.map((t) => t.title)),
      );
      // Tasks are fresh copies, not the same ids as the template.
      expect(
        cloned.tasks.map((t) => t.id),
        isNot(containsAll(template.tasks.map((t) => t.id))),
      );
      // And carry no submissions from the original.
      expect(cloned.tasks.every((t) => t.submissions.isEmpty), isTrue);
    });

    test('cloned game does not appear in the public gallery', () async {
      final template = (await repo.getPublicGamesStream().first).first;
      await repo.cloneGame(template, 'bob', 'Bob');

      final stillPublic = await repo.getPublicGamesStream().first;
      expect(stillPublic.any((g) => g.creatorId == 'bob'), isFalse);
    });

    test('Game.isPublic round-trips through toMap/fromMap', () {
      final game = Game(
        id: 'g1',
        gameName: 'Test',
        creatorId: 'c',
        judgeId: 'c',
        status: GameStatus.lobby,
        inviteCode: 'ABC123',
        createdAt: DateTime(2026, 1, 1),
        players: const [Player(userId: 'c', displayName: 'C', totalScore: 0)],
        tasks: const [
          Task(
            id: 't',
            title: 'x',
            description: 'y',
            taskType: TaskType.video,
            submissions: [],
          ),
        ],
        settings: GameSettings.quickPlay(),
        isPublic: true,
      );

      expect(Game.fromMap(game.toMap()).isPublic, isTrue);
    });
  });
}
