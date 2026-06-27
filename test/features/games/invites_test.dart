import 'package:flutter_test/flutter_test.dart';
import 'package:taskcaster_app/core/models/game.dart';
import 'package:taskcaster_app/core/models/game_settings.dart';
import 'package:taskcaster_app/core/models/player.dart';
import 'package:taskcaster_app/features/games/data/datasources/mock_game_data_source.dart';
import 'package:taskcaster_app/features/games/data/repositories/game_repository_impl.dart';

Game _game({
  required String id,
  required String name,
  required DateTime createdAt,
  List<String> invitedEmails = const [],
  GameStatus status = GameStatus.lobby,
}) {
  return Game(
    id: id,
    gameName: name,
    creatorId: 'creator',
    judgeId: 'creator',
    status: status,
    inviteCode: id.toUpperCase(),
    createdAt: createdAt,
    players: const [
      Player(userId: 'creator', displayName: 'Creator', totalScore: 0),
    ],
    tasks: const [],
    settings: GameSettings.quickPlay(),
    invitedEmails: invitedEmails,
  );
}

void main() {
  group('Game.invitedEmails', () {
    test('round-trips through toMap/fromMap', () {
      final game = _game(
        id: 'g1',
        name: 'Test',
        createdAt: DateTime(2026, 1, 1),
        invitedEmails: const ['alice@example.com', 'bob@example.com'],
      );

      final restored = Game.fromMap(game.toMap());
      expect(restored.invitedEmails, ['alice@example.com', 'bob@example.com']);
    });

    test('defaults to empty list when absent (backward compatible)', () {
      final map = _game(id: 'g1', name: 'Test', createdAt: DateTime(2026, 1, 1))
          .toMap()
        ..remove('invitedEmails');

      expect(Game.fromMap(map).invitedEmails, isEmpty);
    });

    test('fromMap lowercases stored emails', () {
      final map = _game(id: 'g1', name: 'Test', createdAt: DateTime(2026, 1, 1))
          .toMap();
      map['invitedEmails'] = ['MixedCase@Example.COM'];

      expect(Game.fromMap(map).invitedEmails, ['mixedcase@example.com']);
    });
  });

  group('getInvitedGamesStream (mock)', () {
    late MockGameDataSource ds;
    late GameRepositoryImpl repo;

    setUp(() {
      ds = MockGameDataSource();
      repo = GameRepositoryImpl(ds);
    });

    test('returns only invited lobby games, newest first', () async {
      await ds.createGame(_game(
        id: 'old',
        name: 'Older invite',
        createdAt: DateTime(2026, 1, 1),
        invitedEmails: const ['bob@example.com'],
      ).toMap());
      await ds.createGame(_game(
        id: 'new',
        name: 'Newer invite',
        createdAt: DateTime(2026, 3, 1),
        invitedEmails: const ['bob@example.com'],
      ).toMap());
      // Invited but already in progress — must be excluded.
      await ds.createGame(_game(
        id: 'started',
        name: 'Already started',
        createdAt: DateTime(2026, 2, 1),
        invitedEmails: const ['bob@example.com'],
        status: GameStatus.inProgress,
      ).toMap());
      // Lobby game Bob is NOT invited to — must be excluded.
      await ds.createGame(_game(
        id: 'other',
        name: 'Someone else',
        createdAt: DateTime(2026, 2, 15),
        invitedEmails: const ['carol@example.com'],
      ).toMap());

      final games = await repo.getInvitedGamesStream('bob@example.com').first;

      expect(games.map((g) => g.id), ['new', 'old']);
    });

    test('matches case-insensitively', () async {
      await ds.createGame(_game(
        id: 'g1',
        name: 'Case test',
        createdAt: DateTime(2026, 1, 1),
        invitedEmails: const ['bob@example.com'],
      ).toMap());

      final games = await repo.getInvitedGamesStream('BOB@Example.com').first;
      expect(games.map((g) => g.id), ['g1']);
    });

    test('returns empty when nobody is invited', () async {
      final games = await repo.getInvitedGamesStream('nobody@example.com').first;
      expect(games, isEmpty);
    });
  });

  group('inviting a player', () {
    test('adds the lowercased email and surfaces it in getInvitedGamesStream',
        () async {
      final ds = MockGameDataSource();
      final repo = GameRepositoryImpl(ds);

      final game = _game(
        id: 'g1',
        name: 'My party',
        createdAt: DateTime(2026, 1, 1),
      );
      await ds.createGame(game.toMap());

      // Mirror the lobby "Invite by email" action: append the lowercased email
      // and persist via updateGame.
      await repo.updateGame(
        game.id,
        game.copyWith(invitedEmails: [...game.invitedEmails, 'alice@example.com']),
      );

      final stored = await repo.getGameStream('g1').first;
      expect(stored!.invitedEmails, contains('alice@example.com'));

      final invited = await repo.getInvitedGamesStream('alice@example.com').first;
      expect(invited.map((g) => g.id), contains('g1'));
    });
  });
}
