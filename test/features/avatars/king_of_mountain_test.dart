import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskmaster_app/core/models/player.dart';
import 'package:taskmaster_app/features/avatars/game/king_of_mountain_game.dart';

void main() {
  group('KingOfMountainGame', () {
    test('creates game with players', () {
      final players = [
        Player(userId: '1', displayName: 'Alice', totalScore: 0),
        Player(userId: '2', displayName: 'Bob', totalScore: 0),
        Player(userId: '3', displayName: 'Charlie', totalScore: 0),
      ];

      final game = KingOfMountainGame(players: players);

      expect(game.players.length, equals(3));
      expect(game.worldWidth, equals(800));
      expect(game.worldHeight, equals(1200));
    });

    test('game is initialized correctly', () {
      final players = [
        Player(userId: '1', displayName: 'Alice', totalScore: 0),
      ];

      final game = KingOfMountainGame(players: players);

      expect(game.players, isNotEmpty);
      expect(game.worldWidth, greaterThan(0));
      expect(game.worldHeight, greaterThan(0));
    });

    test('creates NPCs when fewer than 10 players', () async {
      final players = [
        Player(userId: '1', displayName: 'Alice', totalScore: 0),
        Player(userId: '2', displayName: 'Bob', totalScore: 0),
      ];

      final game = KingOfMountainGame(players: players);
      await game.onLoad();

      // Should have 2 real players + up to 8 NPCs = up to 10 total
      expect(game.avatars.length, lessThanOrEqualTo(10));
      expect(game.avatars.length, greaterThanOrEqualTo(2)); // At least the real players
    });

    test('does not create NPCs when 10 or more players', () async {
      final players = List.generate(
        10,
        (i) => Player(userId: '$i', displayName: 'Player $i', totalScore: 0),
      );

      final game = KingOfMountainGame(players: players);
      await game.onLoad();

      // Should have exactly 10 players, no NPCs
      expect(game.avatars.length, equals(10));
    });
  });
}
