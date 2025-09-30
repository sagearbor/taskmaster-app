import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskmaster_app/core/models/game.dart';
import 'package:taskmaster_app/core/models/game_settings.dart';
import 'package:taskmaster_app/core/models/player.dart';
import 'package:taskmaster_app/features/games/domain/repositories/game_repository.dart';
import 'package:taskmaster_app/features/games/presentation/bloc/games_bloc.dart';

class MockGameRepository extends Mock implements GameRepository {}

void main() {
  group('GamesBloc Tests', () {
    late GamesBloc gamesBloc;
    late MockGameRepository mockGameRepository;
    late List<Game> testGames;

    setUp(() {
      mockGameRepository = MockGameRepository();
      gamesBloc = GamesBloc(gameRepository: mockGameRepository);
      
      testGames = [
        Game(
          id: 'game1',
          gameName: 'Test Game 1',
          creatorId: 'user1',
          judgeId: 'user1',
          status: GameStatus.lobby,
          inviteCode: 'TEST01',
          createdAt: DateTime.now(),
          players: [
            const Player(userId: 'user1', displayName: 'Alice', totalScore: 0),
          ],
          tasks: [],
          settings: const GameSettings(),
        ),
        Game(
          id: 'game2',
          gameName: 'Test Game 2',
          creatorId: 'user2',
          judgeId: 'user2',
          status: GameStatus.inProgress,
          inviteCode: 'TEST02',
          createdAt: DateTime.now(),
          players: [
            const Player(userId: 'user2', displayName: 'Bob', totalScore: 15),
          ],
          tasks: [],
          settings: const GameSettings(),
        ),
      ];
    });

    tearDown(() {
      gamesBloc.close();
    });

    test('initial state should be GamesInitial', () {
      expect(gamesBloc.state, equals(GamesInitial()));
    });

    group('LoadGames', () {
      blocTest<GamesBloc, GamesState>(
        'emits [GamesLoading, GamesLoaded] when games are loaded successfully',
        build: () {
          when(() => mockGameRepository.getGamesStream())
              .thenAnswer((_) => Stream.value(testGames));
          return gamesBloc;
        },
        act: (bloc) => bloc.add(LoadGames()),
        expect: () => [
          GamesLoading(),
          GamesLoaded(games: testGames),
        ],
      );

      blocTest<GamesBloc, GamesState>(
        'emits [GamesLoading, GamesError] when loading games fails',
        build: () {
          when(() => mockGameRepository.getGamesStream())
              .thenAnswer((_) => Stream.error(Exception('Failed to load games')));
          return gamesBloc;
        },
        act: (bloc) => bloc.add(LoadGames()),
        expect: () => [
          GamesLoading(),
          const GamesError(message: 'Exception: Failed to load games'),
        ],
      );

      blocTest<GamesBloc, GamesState>(
        'emits [GamesLoading, GamesLoaded] with empty list when no games exist',
        build: () {
          when(() => mockGameRepository.getGamesStream())
              .thenAnswer((_) => Stream.value([]));
          return gamesBloc;
        },
        act: (bloc) => bloc.add(LoadGames()),
        expect: () => [
          GamesLoading(),
          const GamesLoaded(games: []),
        ],
      );
    });

    group('CreateGame', () {
      blocTest<GamesBloc, GamesState>(
        'emits [GamesLoading] and calls LoadGames when game is created successfully',
        build: () {
          when(() => mockGameRepository.createGame(any(), any(), any()))
              .thenAnswer((_) async => 'new_game_id');
          when(() => mockGameRepository.getGamesStream())
              .thenAnswer((_) => Stream.value(testGames));
          return gamesBloc;
        },
        act: (bloc) => bloc.add(const CreateGame(
          gameName: 'New Game',
          creatorId: 'user1',
          judgeId: 'user1',
        )),
        expect: () => [
          GamesLoading(),
          GamesLoading(), // From LoadGames call
          GamesLoaded(games: testGames),
        ],
      );

      blocTest<GamesBloc, GamesState>(
        'emits [GamesLoading, GamesError] when game creation fails',
        build: () {
          when(() => mockGameRepository.createGame(any(), any(), any()))
              .thenThrow(Exception('Failed to create game'));
          return gamesBloc;
        },
        act: (bloc) => bloc.add(const CreateGame(
          gameName: 'New Game',
          creatorId: 'user1',
          judgeId: 'user1',
        )),
        expect: () => [
          GamesLoading(),
          const GamesError(message: 'Exception: Failed to create game'),
        ],
      );
    });

    group('JoinGame', () {
      blocTest<GamesBloc, GamesState>(
        'calls LoadGames when game is joined successfully',
        build: () {
          when(() => mockGameRepository.joinGame(any(), any(), any()))
              .thenAnswer((_) async => 'game_id');
          when(() => mockGameRepository.getGamesStream())
              .thenAnswer((_) => Stream.value(testGames));
          return gamesBloc;
        },
        act: (bloc) => bloc.add(const JoinGame(
          inviteCode: 'TEST01',
          userId: 'user2',
          displayName: 'Charlie',
        )),
        expect: () => [
          GamesLoading(),
          GamesLoaded(games: testGames),
        ],
      );

      blocTest<GamesBloc, GamesState>(
        'emits GamesError when joining game fails',
        build: () {
          when(() => mockGameRepository.joinGame(any(), any(), any()))
              .thenThrow(Exception('Game not found'));
          return gamesBloc;
        },
        act: (bloc) => bloc.add(const JoinGame(
          inviteCode: 'INVALID',
          userId: 'user2',
          displayName: 'Charlie',
        )),
        expect: () => [
          const GamesError(message: 'Exception: Game not found'),
        ],
      );
    });

    group('DeleteGame', () {
      blocTest<GamesBloc, GamesState>(
        'calls LoadGames when game is deleted successfully',
        build: () {
          when(() => mockGameRepository.deleteGame(any()))
              .thenAnswer((_) async {});
          when(() => mockGameRepository.getGamesStream())
              .thenAnswer((_) => Stream.value([]));
          return gamesBloc;
        },
        act: (bloc) => bloc.add(const DeleteGame(gameId: 'game1')),
        expect: () => [
          GamesLoading(),
          const GamesLoaded(games: []),
        ],
      );

      blocTest<GamesBloc, GamesState>(
        'emits GamesError when deleting game fails',
        build: () {
          when(() => mockGameRepository.deleteGame(any()))
              .thenThrow(Exception('Failed to delete game'));
          return gamesBloc;
        },
        act: (bloc) => bloc.add(const DeleteGame(gameId: 'game1')),
        expect: () => [
          const GamesError(message: 'Exception: Failed to delete game'),
        ],
      );
    });

    group('Multiple Events', () {
      blocTest<GamesBloc, GamesState>(
        'handles multiple events correctly',
        build: () {
          when(() => mockGameRepository.createGame(any(), any(), any()))
              .thenAnswer((_) async => 'new_game_id');
          when(() => mockGameRepository.getGamesStream())
              .thenAnswer((_) => Stream.value(testGames));
          return gamesBloc;
        },
        act: (bloc) {
          bloc.add(LoadGames());
          bloc.add(const CreateGame(
            gameName: 'New Game',
            creatorId: 'user1',
            judgeId: 'user1',
          ));
        },
        expect: () => [
          GamesLoading(),
          GamesLoaded(games: testGames),
          GamesLoading(),
          GamesLoading(),
          GamesLoaded(games: testGames),
        ],
      );
    });
  });
}