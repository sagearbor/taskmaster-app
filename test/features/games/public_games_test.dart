import 'package:flutter_test/flutter_test.dart';
import 'package:taskcaster_app/core/models/game.dart';
import 'package:taskcaster_app/core/models/game_settings.dart';
import 'package:taskcaster_app/core/models/player.dart';
import 'package:taskcaster_app/core/models/task.dart';
import 'package:taskcaster_app/features/games/data/datasources/mock_game_data_source.dart';
import 'package:taskcaster_app/features/games/data/repositories/game_repository_impl.dart';

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

    test('cloneGame increments the template clone counter', () async {
      final template = (await repo.getPublicGamesStream().first)
          .firstWhere((g) => g.gameName == 'Weekend Warriors');
      final before = template.cloneCount;

      await repo.cloneGame(template, 'alice', 'Alice');

      final after = (await repo.getPublicGamesStream().first)
          .firstWhere((g) => g.id == template.id);
      expect(after.cloneCount, before + 1);
    });

    test('public gallery is sorted most-cloned first', () async {
      // Clone "Epic Adventure" a few times so it overtakes the others.
      final epic = (await repo.getPublicGamesStream().first)
          .firstWhere((g) => g.gameName == 'Epic Adventure');
      for (var i = 0; i < 3; i++) {
        final fresh = (await repo.getPublicGamesStream().first)
            .firstWhere((g) => g.id == epic.id);
        await repo.cloneGame(fresh, 'p$i', 'P$i');
      }

      final games = await repo.getPublicGamesStream().first;
      expect(games.first.gameName, 'Epic Adventure');
      // Sorted descending by cloneCount.
      for (var i = 0; i < games.length - 1; i++) {
        expect(games[i].cloneCount,
            greaterThanOrEqualTo(games[i + 1].cloneCount));
      }
    });

    test('seedStarterPublicGames creates public games owned by the caller',
        () async {
      // Use a fresh repo with no seeded mock games to isolate.
      final r = GameRepositoryImpl(MockGameDataSource());
      await r.seedStarterPublicGames('alice', 'Alice');

      final games = await r.getPublicGamesStream().first;
      final mine = games.where((g) => g.creatorId == 'alice').toList();
      expect(mine.length, greaterThanOrEqualTo(3));
      expect(mine.every((g) => g.isPublic), isTrue);
      expect(mine.every((g) => g.tasks.isNotEmpty), isTrue);
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
