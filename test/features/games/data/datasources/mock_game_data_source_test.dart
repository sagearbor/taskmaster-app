import 'package:flutter_test/flutter_test.dart';
import 'package:taskmaster_app/features/games/data/datasources/mock_game_data_source.dart';

void main() {
  late MockGameDataSource dataSource;

  setUp(() {
    dataSource = MockGameDataSource();
  });

  tearDown(() {
    dataSource.dispose();
  });

  group('MockGameDataSource - Initialization', () {
    test('should initialize with 5 mock games', () async {
      final games = await dataSource.getGamesStream().first;
      expect(games.length, 5);
    });

    test('should have games in different states', () async {
      final games = await dataSource.getGamesStream().first;

      final statuses = games.map((g) => g['status'] as String).toSet();
      expect(statuses.contains('lobby'), true);
      expect(statuses.contains('inProgress'), true);
      expect(statuses.contains('completed'), true);
    });

    test('should have games with proper structure', () async {
      final games = await dataSource.getGamesStream().first;
      final game = games.first;

      expect(game['id'], isNotNull);
      expect(game['gameName'], isNotNull);
      expect(game['creatorId'], isNotNull);
      expect(game['judgeId'], isNotNull);
      expect(game['status'], isNotNull);
      expect(game['inviteCode'], isNotNull);
      expect(game['mode'], isNotNull);
      expect(game['currentTaskIndex'], isNotNull);
      expect(game['settings'], isNotNull);
      expect(game['players'], isNotNull);
      expect(game['tasks'], isNotNull);
    });

    test('should have tasks with new async fields', () async {
      final games = await dataSource.getGamesStream().first;
      final game = games.first;
      final task = (game['tasks'] as List).first as Map<String, dynamic>;

      expect(task['status'], isNotNull);
      expect(task['playerStatuses'], isNotNull);
      expect(task['durationSeconds'], isNotNull);
      expect(task['modifiers'], isNotNull);
    });
  });

  group('MockGameDataSource - CRUD Operations', () {
    test('should create a new game', () async {
      final newGame = {
        'id': 'test_game_1',
        'gameName': 'Test Game',
        'creatorId': 'test_user_1',
        'judgeId': 'test_user_2',
        'status': 'lobby',
        'inviteCode': 'TEST123',
        'mode': 'async',
        'currentTaskIndex': 0,
        'createdAt': DateTime.now().toIso8601String(),
        'settings': {
          'taskDeadlineHours': 24,
          'autoAdvance': true,
          'allowSkips': true,
          'maxPlayers': 10,
        },
        'players': [
          {'userId': 'test_user_1', 'displayName': 'Test User 1', 'totalScore': 0},
          {'userId': 'test_user_2', 'displayName': 'Test User 2', 'totalScore': 0},
        ],
        'tasks': [],
      };

      final gameId = await dataSource.createGame(newGame);
      expect(gameId, 'test_game_1');

      final games = await dataSource.getGamesStream().first;
      expect(games.length, 6);
      expect(games.any((g) => g['id'] == 'test_game_1'), true);
    });

    test('should update an existing game', () async {
      final games = await dataSource.getGamesStream().first;
      final gameId = games.first['id'] as String;

      await dataSource.updateGame(gameId, {'gameName': 'Updated Game Name'});

      final updatedGames = await dataSource.getGamesStream().first;
      final updatedGame = updatedGames.firstWhere((g) => g['id'] == gameId);
      expect(updatedGame['gameName'], 'Updated Game Name');
    });

    test('should delete a game', () async {
      final games = await dataSource.getGamesStream().first;
      final initialCount = games.length;
      final gameId = games.first['id'] as String;

      await dataSource.deleteGame(gameId);

      final remainingGames = await dataSource.getGamesStream().first;
      expect(remainingGames.length, initialCount - 1);
      expect(remainingGames.any((g) => g['id'] == gameId), false);
    });

    test('should get a specific game stream', () async {
      final games = await dataSource.getGamesStream().first;
      final gameId = games.first['id'] as String;

      final gameStream = dataSource.getGameStream(gameId);
      final game = await gameStream.first;

      expect(game, isNotNull);
      expect(game!['id'], gameId);
    });

    test('should return null for non-existent game', () async {
      final gameStream = dataSource.getGameStream('non_existent_id');
      final game = await gameStream.first;

      expect(game, isNull);
    });
  });

  group('MockGameDataSource - Join Game', () {
    test('should allow user to join game with valid invite code', () async {
      final games = await dataSource.getGamesStream().first;
      final inviteCode = games.first['inviteCode'] as String;

      final gameId = await dataSource.joinGame(inviteCode, 'new_user_123');

      final updatedGames = await dataSource.getGamesStream().first;
      final game = updatedGames.firstWhere((g) => g['id'] == gameId);
      final players = game['players'] as List;

      expect(players.any((p) => p['userId'] == 'new_user_123'), true);
    });

    test('should not duplicate user if already in game', () async {
      final games = await dataSource.getGamesStream().first;
      final game = games.first;
      final inviteCode = game['inviteCode'] as String;
      final existingUserId = (game['players'] as List).first['userId'] as String;

      await dataSource.joinGame(inviteCode, existingUserId);

      final updatedGames = await dataSource.getGamesStream().first;
      final updatedGame = updatedGames.firstWhere((g) => g['id'] == game['id']);
      final players = updatedGame['players'] as List;

      expect(
        players.where((p) => p['userId'] == existingUserId).length,
        1,
      );
    });

    test('should throw exception for invalid invite code', () async {
      expect(
        () => dataSource.joinGame('INVALID_CODE', 'user_123'),
        throwsException,
      );
    });

    test('should throw exception when game is full', () async {
      // Create a game with maxPlayers = 2
      final newGame = {
        'id': 'full_game',
        'gameName': 'Full Game',
        'creatorId': 'user_1',
        'judgeId': 'user_2',
        'status': 'lobby',
        'inviteCode': 'FULL',
        'mode': 'async',
        'currentTaskIndex': 0,
        'createdAt': DateTime.now().toIso8601String(),
        'settings': {
          'taskDeadlineHours': 24,
          'autoAdvance': true,
          'allowSkips': true,
          'maxPlayers': 2,
        },
        'players': [
          {'userId': 'user_1', 'displayName': 'User 1', 'totalScore': 0},
          {'userId': 'user_2', 'displayName': 'User 2', 'totalScore': 0},
        ],
        'tasks': [],
      };

      await dataSource.createGame(newGame);

      expect(
        () => dataSource.joinGame('FULL', 'user_3'),
        throwsException,
      );
    });
  });

  group('MockGameDataSource - State Transitions', () {
    test('should initialize playerStatuses when starting game', () async {
      // Create a game with tasks
      final newGame = {
        'id': 'state_test_game',
        'gameName': 'State Test',
        'creatorId': 'user_1',
        'judgeId': 'user_2',
        'status': 'lobby',
        'inviteCode': 'STATE',
        'mode': 'async',
        'currentTaskIndex': 0,
        'createdAt': DateTime.now().toIso8601String(),
        'settings': {
          'taskDeadlineHours': 24,
          'autoAdvance': true,
          'allowSkips': true,
          'maxPlayers': 10,
        },
        'players': [
          {'userId': 'user_1', 'displayName': 'User 1', 'totalScore': 0},
          {'userId': 'user_2', 'displayName': 'User 2', 'totalScore': 0},
        ],
        'tasks': [
          {
            'id': 'task_1',
            'title': 'Test Task',
            'description': 'Do something',
            'taskType': 'video',
            'puzzleAnswer': null,
            'status': 'waiting_for_submissions',
            'deadline': null,
            'durationSeconds': 300,
            'playerStatuses': {},
            'submissions': [],
            'modifiers': [],
          }
        ],
      };

      final gameId = await dataSource.createGame(newGame);

      // Start the game
      await dataSource.updateGame(gameId, {
        'status': 'inProgress',
        'currentTaskIndex': 0,
      });

      final games = await dataSource.getGamesStream().first;
      final game = games.firstWhere((g) => g['id'] == gameId);
      final task = (game['tasks'] as List).first as Map<String, dynamic>;
      final playerStatuses = task['playerStatuses'] as Map<String, dynamic>;

      expect(playerStatuses.isNotEmpty, true);
      expect(playerStatuses.containsKey('user_1'), true);
      expect(playerStatuses.containsKey('user_2'), true);
      expect(playerStatuses['user_1']['state'], 'not_started');
      expect(task['deadline'], isNotNull);
    });

    test('should update game and reflect in stream', () async {
      final games = await dataSource.getGamesStream().first;
      final gameId = games.first['id'] as String;

      // Update game
      await dataSource.updateGame(gameId, {'gameName': 'Stream Test'});

      // Get game stream and verify it has the updated value
      final gameStream = dataSource.getGameStream(gameId);
      final game = await gameStream.first;

      expect(game!['gameName'], 'Stream Test');
    });
  });

  group('MockGameDataSource - Realistic Delays', () {
    test('createGame should have realistic delay', () async {
      final stopwatch = Stopwatch()..start();

      final newGame = {
        'id': 'delay_test',
        'gameName': 'Delay Test',
        'creatorId': 'user_1',
        'judgeId': 'user_2',
        'status': 'lobby',
        'inviteCode': 'DELAY',
        'mode': 'async',
        'currentTaskIndex': 0,
        'createdAt': DateTime.now().toIso8601String(),
        'settings': {
          'taskDeadlineHours': 24,
          'autoAdvance': true,
          'allowSkips': true,
          'maxPlayers': 10,
        },
        'players': [],
        'tasks': [],
      };

      await dataSource.createGame(newGame);
      stopwatch.stop();

      // Should be between 500ms and 1500ms
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(500));
      expect(stopwatch.elapsedMilliseconds, lessThan(1600));
    });

    test('updateGame should have realistic delay', () async {
      final games = await dataSource.getGamesStream().first;
      final gameId = games.first['id'] as String;

      final stopwatch = Stopwatch()..start();
      await dataSource.updateGame(gameId, {'gameName': 'Delay Test'});
      stopwatch.stop();

      // Should be between 200ms and 800ms
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(200));
      expect(stopwatch.elapsedMilliseconds, lessThan(900));
    });

    test('joinGame should have realistic delay', () async {
      final games = await dataSource.getGamesStream().first;
      final inviteCode = games.first['inviteCode'] as String;

      final stopwatch = Stopwatch()..start();
      await dataSource.joinGame(inviteCode, 'delay_user');
      stopwatch.stop();

      // Should be between 400ms and 1200ms
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(400));
      expect(stopwatch.elapsedMilliseconds, lessThan(1300));
    });
  });

  group('MockGameDataSource - Data Persistence', () {
    test('should persist data within session', () async {
      final newGame = {
        'id': 'persist_test',
        'gameName': 'Persistence Test',
        'creatorId': 'user_1',
        'judgeId': 'user_2',
        'status': 'lobby',
        'inviteCode': 'PERSIST',
        'mode': 'async',
        'currentTaskIndex': 0,
        'createdAt': DateTime.now().toIso8601String(),
        'settings': {
          'taskDeadlineHours': 24,
          'autoAdvance': true,
          'allowSkips': true,
          'maxPlayers': 10,
        },
        'players': [],
        'tasks': [],
      };

      await dataSource.createGame(newGame);

      // Update the game
      await dataSource.updateGame('persist_test', {'gameName': 'Updated Persistence'});

      // Get the game stream
      final gameStream = dataSource.getGameStream('persist_test');
      final game = await gameStream.first;

      expect(game!['gameName'], 'Updated Persistence');
    });
  });
}