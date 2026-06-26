import 'package:flutter_test/flutter_test.dart';
import 'package:taskcaster_app/features/games/data/datasources/mock_game_data_source.dart';
import 'package:taskcaster_app/features/games/data/repositories/game_repository_impl.dart';

void main() {
  group('GameRepositoryImpl.leaveGame', () {
    late MockGameDataSource dataSource;
    late GameRepositoryImpl repository;

    setUp(() {
      dataSource = MockGameDataSource();
      repository = GameRepositoryImpl(dataSource);
    });

    tearDown(() => dataSource.dispose());

    test('removes the player from the roster', () async {
      // game_1 is seeded with players user_123, user_456, user_789.
      final before = await repository.getGameStream('game_1').first;
      expect(before, isNotNull);
      expect(before!.players.any((p) => p.userId == 'user_789'), isTrue);
      final originalCount = before.players.length;

      await repository.leaveGame('game_1', 'user_789');

      final after = await repository.getGameStream('game_1').first;
      expect(after!.players.any((p) => p.userId == 'user_789'), isFalse);
      expect(after.players.length, originalCount - 1);
    });

    test('is a no-op when the user is not a player', () async {
      final before = await repository.getGameStream('game_1').first;
      final originalCount = before!.players.length;

      await repository.leaveGame('game_1', 'not_a_member');

      final after = await repository.getGameStream('game_1').first;
      expect(after!.players.length, originalCount);
    });
  });
}
