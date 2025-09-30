import 'dart:async';
import 'dart:math';

import 'game_remote_data_source.dart';

class MockGameDataSource implements GameRemoteDataSource {
  final StreamController<List<Map<String, dynamic>>> _gamesController = 
      StreamController<List<Map<String, dynamic>>>.broadcast();
  
  final Map<String, StreamController<Map<String, dynamic>?>> _gameControllers = {};
  
  final List<Map<String, dynamic>> _games = [];
  final Random _random = Random();

  MockGameDataSource() {
    _initializeMockGames();
  }

  void _initializeMockGames() {
    final now = DateTime.now();
    final mockGames = [
      // Game 1: Lobby state - waiting to start
      {
        'id': 'game_1',
        'gameName': 'Saturday Night Shenanigans',
        'creatorId': 'user_123',
        'judgeId': 'user_456',
        'status': 'lobby',
        'inviteCode': 'PARTY1',
        'mode': 'async',
        'currentTaskIndex': 0,
        'createdAt': now.subtract(const Duration(hours: 2)).toIso8601String(),
        'settings': {
          'taskDeadlineHours': 24,
          'autoAdvance': true,
          'allowSkips': true,
          'maxPlayers': 10,
        },
        'players': [
          {'userId': 'user_123', 'displayName': 'Alice the Creator', 'totalScore': 0},
          {'userId': 'user_456', 'displayName': 'Bob the Judge', 'totalScore': 0},
          {'userId': 'user_789', 'displayName': 'Charlie', 'totalScore': 0},
        ],
        'tasks': [
          {
            'id': 'task_1',
            'title': 'Make the most magnificent sandwich',
            'description': 'Create a sandwich using only items you can find in your kitchen right now. Points for creativity, presentation, and explaining your choices.',
            'taskType': 'video',
            'puzzleAnswer': null,
            'status': 'waiting_for_submissions',
            'deadline': null,
            'durationSeconds': 300,
            'playerStatuses': {},
            'submissions': [],
            'modifiers': [],
          },
          {
            'id': 'task_2',
            'title': 'Wear the most items of clothing',
            'description': 'Put on as many individual items of clothing as possible. Each item must be visible and properly worn.',
            'taskType': 'video',
            'puzzleAnswer': null,
            'status': 'waiting_for_submissions',
            'deadline': null,
            'durationSeconds': 180,
            'playerStatuses': {},
            'submissions': [],
            'modifiers': [],
          }
        ]
      },
      // Game 2: In-progress - waiting for submissions
      {
        'id': 'game_2',
        'gameName': 'Family Game Night',
        'creatorId': 'user_789',
        'judgeId': 'user_101',
        'status': 'inProgress',
        'inviteCode': 'FAMILY',
        'mode': 'async',
        'currentTaskIndex': 0,
        'createdAt': now.subtract(const Duration(hours: 1)).toIso8601String(),
        'settings': {
          'taskDeadlineHours': 24,
          'autoAdvance': true,
          'allowSkips': true,
          'maxPlayers': 10,
        },
        'players': [
          {'userId': 'user_789', 'displayName': 'Charlie', 'totalScore': 0},
          {'userId': 'user_101', 'displayName': 'Diana the Judge', 'totalScore': 0},
          {'userId': 'user_202', 'displayName': 'Eve', 'totalScore': 0},
          {'userId': 'user_303', 'displayName': 'Frank', 'totalScore': 0},
        ],
        'tasks': [
          {
            'id': 'task_3',
            'title': 'Build the tallest tower',
            'description': 'Using only books, build the tallest possible tower that can stand for at least 10 seconds.',
            'taskType': 'video',
            'puzzleAnswer': null,
            'status': 'waiting_for_submissions',
            'deadline': now.add(const Duration(hours: 22)).toIso8601String(),
            'durationSeconds': 180,
            'playerStatuses': {
              'user_789': {
                'state': 'submitted',
                'videoUrl': 'https://youtube.com/watch?v=fake1',
                'textAnswer': null,
                'score': null,
                'submittedAt': now.subtract(const Duration(minutes: 30)).toIso8601String(),
              },
              'user_101': {
                'state': 'not_started',
                'videoUrl': null,
                'textAnswer': null,
                'score': null,
                'submittedAt': null,
              },
              'user_202': {
                'state': 'in_progress',
                'videoUrl': null,
                'textAnswer': null,
                'score': null,
                'submittedAt': null,
              },
              'user_303': {
                'state': 'not_started',
                'videoUrl': null,
                'textAnswer': null,
                'score': null,
                'submittedAt': null,
              },
            },
            'submissions': [
              {
                'id': 'sub_1',
                'userId': 'user_789',
                'videoUrl': 'https://youtube.com/watch?v=fake1',
                'textAnswer': null,
                'score': null,
                'isJudged': false,
                'submittedAt': now.subtract(const Duration(minutes: 30)).toIso8601String(),
              }
            ],
            'modifiers': [],
          },
          {
            'id': 'task_4',
            'title': 'Dance like nobody\'s watching',
            'description': 'Create a 30-second dance routine. Bonus points for incorporating household items as props.',
            'taskType': 'video',
            'puzzleAnswer': null,
            'status': 'waiting_for_submissions',
            'deadline': null,
            'durationSeconds': 30,
            'playerStatuses': {},
            'submissions': [],
            'modifiers': [],
          }
        ]
      },
      // Game 3: Ready to judge - all players submitted
      {
        'id': 'game_3',
        'gameName': 'Weekend Warriors',
        'creatorId': 'user_404',
        'judgeId': 'user_505',
        'status': 'inProgress',
        'inviteCode': 'WARRIORS',
        'mode': 'async',
        'currentTaskIndex': 0,
        'createdAt': now.subtract(const Duration(hours: 5)).toIso8601String(),
        'settings': {
          'taskDeadlineHours': 24,
          'autoAdvance': true,
          'allowSkips': true,
          'maxPlayers': 10,
        },
        'players': [
          {'userId': 'user_404', 'displayName': 'Grace', 'totalScore': 0},
          {'userId': 'user_505', 'displayName': 'Henry the Judge', 'totalScore': 0},
          {'userId': 'user_606', 'displayName': 'Ivy', 'totalScore': 0},
        ],
        'tasks': [
          {
            'id': 'task_5',
            'title': 'Draw a self-portrait using only office supplies',
            'description': 'Create a recognizable self-portrait using only items you can find in an office.',
            'taskType': 'video',
            'puzzleAnswer': null,
            'status': 'ready_to_judge',
            'deadline': now.add(const Duration(hours: 19)).toIso8601String(),
            'durationSeconds': 300,
            'playerStatuses': {
              'user_404': {
                'state': 'submitted',
                'videoUrl': 'https://youtube.com/watch?v=portrait1',
                'textAnswer': null,
                'score': null,
                'submittedAt': now.subtract(const Duration(hours: 2)).toIso8601String(),
              },
              'user_505': {
                'state': 'not_started',
                'videoUrl': null,
                'textAnswer': null,
                'score': null,
                'submittedAt': null,
              },
              'user_606': {
                'state': 'submitted',
                'videoUrl': 'https://youtube.com/watch?v=portrait2',
                'textAnswer': null,
                'score': null,
                'submittedAt': now.subtract(const Duration(hours: 1)).toIso8601String(),
              },
            },
            'submissions': [
              {
                'id': 'sub_3',
                'userId': 'user_404',
                'videoUrl': 'https://youtube.com/watch?v=portrait1',
                'textAnswer': null,
                'score': null,
                'isJudged': false,
                'submittedAt': now.subtract(const Duration(hours: 2)).toIso8601String(),
              },
              {
                'id': 'sub_4',
                'userId': 'user_606',
                'videoUrl': 'https://youtube.com/watch?v=portrait2',
                'textAnswer': null,
                'score': null,
                'isJudged': false,
                'submittedAt': now.subtract(const Duration(hours: 1)).toIso8601String(),
              }
            ],
            'modifiers': [],
          },
          {
            'id': 'task_6',
            'title': 'Solve a riddle',
            'description': 'What has keys but no locks, space but no room, and you can enter but can\'t go inside?',
            'taskType': 'puzzle',
            'puzzleAnswer': 'keyboard',
            'status': 'waiting_for_submissions',
            'deadline': null,
            'durationSeconds': 60,
            'playerStatuses': {},
            'submissions': [],
            'modifiers': [],
          }
        ]
      },
      // Game 4: Mid-game - task 2 in progress, task 1 completed
      {
        'id': 'game_4',
        'gameName': 'Epic Adventure',
        'creatorId': 'user_999',
        'judgeId': 'user_888',
        'status': 'inProgress',
        'inviteCode': 'EPIC99',
        'mode': 'async',
        'currentTaskIndex': 1,
        'createdAt': now.subtract(const Duration(days: 1)).toIso8601String(),
        'settings': {
          'taskDeadlineHours': 48,
          'autoAdvance': true,
          'allowSkips': false,
          'maxPlayers': 8,
        },
        'players': [
          {'userId': 'user_999', 'displayName': 'Max', 'totalScore': 5},
          {'userId': 'user_888', 'displayName': 'Luna the Judge', 'totalScore': 0},
          {'userId': 'user_777', 'displayName': 'Nova', 'totalScore': 3},
          {'userId': 'user_666', 'displayName': 'Zara', 'totalScore': 4},
        ],
        'tasks': [
          {
            'id': 'task_7',
            'title': 'Create an origami masterpiece',
            'description': 'Fold a piece of paper into the most impressive origami creation you can manage.',
            'taskType': 'video',
            'puzzleAnswer': null,
            'status': 'completed',
            'deadline': now.subtract(const Duration(hours: 12)).toIso8601String(),
            'durationSeconds': 600,
            'playerStatuses': {
              'user_999': {
                'state': 'judged',
                'videoUrl': 'https://youtube.com/watch?v=origami1',
                'textAnswer': null,
                'score': 5,
                'submittedAt': now.subtract(const Duration(hours: 24)).toIso8601String(),
              },
              'user_888': {
                'state': 'skipped',
                'videoUrl': null,
                'textAnswer': null,
                'score': 0,
                'submittedAt': null,
              },
              'user_777': {
                'state': 'judged',
                'videoUrl': 'https://youtube.com/watch?v=origami2',
                'textAnswer': null,
                'score': 3,
                'submittedAt': now.subtract(const Duration(hours: 20)).toIso8601String(),
              },
              'user_666': {
                'state': 'judged',
                'videoUrl': 'https://youtube.com/watch?v=origami3',
                'textAnswer': null,
                'score': 4,
                'submittedAt': now.subtract(const Duration(hours: 18)).toIso8601String(),
              },
            },
            'submissions': [
              {
                'id': 'sub_5',
                'userId': 'user_999',
                'videoUrl': 'https://youtube.com/watch?v=origami1',
                'textAnswer': null,
                'score': 5,
                'isJudged': true,
                'submittedAt': now.subtract(const Duration(hours: 24)).toIso8601String(),
              },
              {
                'id': 'sub_6',
                'userId': 'user_777',
                'videoUrl': 'https://youtube.com/watch?v=origami2',
                'textAnswer': null,
                'score': 3,
                'isJudged': true,
                'submittedAt': now.subtract(const Duration(hours: 20)).toIso8601String(),
              },
              {
                'id': 'sub_7',
                'userId': 'user_666',
                'videoUrl': 'https://youtube.com/watch?v=origami3',
                'textAnswer': null,
                'score': 4,
                'isJudged': true,
                'submittedAt': now.subtract(const Duration(hours: 18)).toIso8601String(),
              }
            ],
            'modifiers': [],
          },
          {
            'id': 'task_8',
            'title': 'Beatbox battle',
            'description': 'Record yourself beatboxing for 15 seconds. Creativity and rhythm count!',
            'taskType': 'video',
            'puzzleAnswer': null,
            'status': 'waiting_for_submissions',
            'deadline': now.add(const Duration(hours: 36)).toIso8601String(),
            'durationSeconds': 15,
            'playerStatuses': {
              'user_999': {
                'state': 'in_progress',
                'videoUrl': null,
                'textAnswer': null,
                'score': null,
                'submittedAt': null,
              },
              'user_888': {
                'state': 'not_started',
                'videoUrl': null,
                'textAnswer': null,
                'score': null,
                'submittedAt': null,
              },
              'user_777': {
                'state': 'not_started',
                'videoUrl': null,
                'textAnswer': null,
                'score': null,
                'submittedAt': null,
              },
              'user_666': {
                'state': 'submitted',
                'videoUrl': 'https://youtube.com/watch?v=beatbox1',
                'textAnswer': null,
                'score': null,
                'submittedAt': now.subtract(const Duration(minutes: 15)).toIso8601String(),
              },
            },
            'submissions': [
              {
                'id': 'sub_8',
                'userId': 'user_666',
                'videoUrl': 'https://youtube.com/watch?v=beatbox1',
                'textAnswer': null,
                'score': null,
                'isJudged': false,
                'submittedAt': now.subtract(const Duration(minutes: 15)).toIso8601String(),
              }
            ],
            'modifiers': [],
          },
          {
            'id': 'task_9',
            'title': 'Make a paper airplane that flies the furthest',
            'description': 'Design and throw a paper airplane. Record the flight!',
            'taskType': 'video',
            'puzzleAnswer': null,
            'status': 'waiting_for_submissions',
            'deadline': null,
            'durationSeconds': 120,
            'playerStatuses': {},
            'submissions': [],
            'modifiers': [],
          }
        ]
      },
      // Game 5: Completed game
      {
        'id': 'game_5',
        'gameName': 'Office Competition',
        'creatorId': 'user_111',
        'judgeId': 'user_222',
        'status': 'completed',
        'inviteCode': 'OFFICE',
        'mode': 'async',
        'currentTaskIndex': 2,
        'createdAt': now.subtract(const Duration(days: 3)).toIso8601String(),
        'settings': {
          'taskDeadlineHours': 24,
          'autoAdvance': true,
          'allowSkips': true,
          'maxPlayers': 10,
        },
        'players': [
          {'userId': 'user_111', 'displayName': 'Alex', 'totalScore': 22},
          {'userId': 'user_222', 'displayName': 'Blake the Judge', 'totalScore': 0},
          {'userId': 'user_333', 'displayName': 'Casey', 'totalScore': 18},
          {'userId': 'user_444', 'displayName': 'Drew', 'totalScore': 25},
        ],
        'tasks': [
          {
            'id': 'task_10',
            'title': 'Make coffee art',
            'description': 'Create the most artistic coffee or latte you can manage.',
            'taskType': 'video',
            'puzzleAnswer': null,
            'status': 'completed',
            'deadline': now.subtract(const Duration(days: 2)).toIso8601String(),
            'durationSeconds': 180,
            'playerStatuses': {
              'user_111': {
                'state': 'judged',
                'videoUrl': 'https://youtube.com/watch?v=coffee1',
                'textAnswer': null,
                'score': 4,
                'submittedAt': now.subtract(const Duration(days: 2, hours: 3)).toIso8601String(),
              },
              'user_222': {
                'state': 'skipped',
                'videoUrl': null,
                'textAnswer': null,
                'score': 0,
                'submittedAt': null,
              },
              'user_333': {
                'state': 'judged',
                'videoUrl': 'https://youtube.com/watch?v=coffee2',
                'textAnswer': null,
                'score': 3,
                'submittedAt': now.subtract(const Duration(days: 2, hours: 5)).toIso8601String(),
              },
              'user_444': {
                'state': 'judged',
                'videoUrl': 'https://youtube.com/watch?v=coffee3',
                'textAnswer': null,
                'score': 5,
                'submittedAt': now.subtract(const Duration(days: 2, hours: 4)).toIso8601String(),
              },
            },
            'submissions': [
              {
                'id': 'sub_9',
                'userId': 'user_111',
                'videoUrl': 'https://youtube.com/watch?v=coffee1',
                'textAnswer': null,
                'score': 4,
                'isJudged': true,
                'submittedAt': now.subtract(const Duration(days: 2, hours: 3)).toIso8601String(),
              },
              {
                'id': 'sub_10',
                'userId': 'user_333',
                'videoUrl': 'https://youtube.com/watch?v=coffee2',
                'textAnswer': null,
                'score': 3,
                'isJudged': true,
                'submittedAt': now.subtract(const Duration(days: 2, hours: 5)).toIso8601String(),
              },
              {
                'id': 'sub_11',
                'userId': 'user_444',
                'videoUrl': 'https://youtube.com/watch?v=coffee3',
                'textAnswer': null,
                'score': 5,
                'isJudged': true,
                'submittedAt': now.subtract(const Duration(days: 2, hours: 4)).toIso8601String(),
              }
            ],
            'modifiers': [],
          },
          {
            'id': 'task_11',
            'title': 'Stack sticky notes',
            'description': 'How many sticky notes can you stack before they fall?',
            'taskType': 'video',
            'puzzleAnswer': null,
            'status': 'completed',
            'deadline': now.subtract(const Duration(days: 1)).toIso8601String(),
            'durationSeconds': 120,
            'playerStatuses': {
              'user_111': {
                'state': 'judged',
                'videoUrl': 'https://youtube.com/watch?v=sticky1',
                'textAnswer': null,
                'score': 5,
                'submittedAt': now.subtract(const Duration(days: 1, hours: 3)).toIso8601String(),
              },
              'user_222': {
                'state': 'skipped',
                'videoUrl': null,
                'textAnswer': null,
                'score': 0,
                'submittedAt': null,
              },
              'user_333': {
                'state': 'judged',
                'videoUrl': 'https://youtube.com/watch?v=sticky2',
                'textAnswer': null,
                'score': 4,
                'submittedAt': now.subtract(const Duration(days: 1, hours: 2)).toIso8601String(),
              },
              'user_444': {
                'state': 'judged',
                'videoUrl': 'https://youtube.com/watch?v=sticky3',
                'textAnswer': null,
                'score': 5,
                'submittedAt': now.subtract(const Duration(days: 1, hours: 1)).toIso8601String(),
              },
            },
            'submissions': [
              {
                'id': 'sub_12',
                'userId': 'user_111',
                'videoUrl': 'https://youtube.com/watch?v=sticky1',
                'textAnswer': null,
                'score': 5,
                'isJudged': true,
                'submittedAt': now.subtract(const Duration(days: 1, hours: 3)).toIso8601String(),
              },
              {
                'id': 'sub_13',
                'userId': 'user_333',
                'videoUrl': 'https://youtube.com/watch?v=sticky2',
                'textAnswer': null,
                'score': 4,
                'isJudged': true,
                'submittedAt': now.subtract(const Duration(days: 1, hours: 2)).toIso8601String(),
              },
              {
                'id': 'sub_14',
                'userId': 'user_444',
                'videoUrl': 'https://youtube.com/watch?v=sticky3',
                'textAnswer': null,
                'score': 5,
                'isJudged': true,
                'submittedAt': now.subtract(const Duration(days: 1, hours: 1)).toIso8601String(),
              }
            ],
            'modifiers': [],
          }
        ]
      }
    ];

    _games.addAll(mockGames);
    _gamesController.add(_games);
  }

  @override
  Stream<List<Map<String, dynamic>>> getGamesStream() async* {
    // Emit initial data immediately
    yield List.from(_games);
    // Then emit all future updates
    await for (final games in _gamesController.stream) {
      yield games;
    }
  }

  @override
  Future<String> createGame(Map<String, dynamic> gameData) async {
    // Simulate realistic network delay (500ms-1.5s)
    await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(1000)));

    _games.add(gameData);
    _gamesController.add(List.from(_games));

    return gameData['id'] as String;
  }

  @override
  Future<void> updateGame(String gameId, Map<String, dynamic> updates) async {
    // Simulate realistic network delay (200ms-800ms)
    await Future.delayed(Duration(milliseconds: 200 + _random.nextInt(600)));

    final gameIndex = _games.indexWhere((game) => game['id'] == gameId);
    if (gameIndex != -1) {
      // Deep merge to handle nested updates like updating specific task or player
      final game = _games[gameIndex];

      // Handle status transitions for realistic state management
      if (updates.containsKey('status')) {
        final newStatus = updates['status'];
        if (newStatus == 'inProgress' && game['status'] == 'lobby') {
          // Initialize playerStatuses for first task when starting game
          if (game['tasks'] != null && (game['tasks'] as List).isNotEmpty) {
            final tasks = List<Map<String, dynamic>>.from(game['tasks']);
            if (tasks.isNotEmpty && updates.containsKey('currentTaskIndex')) {
              final currentTaskIndex = updates['currentTaskIndex'] as int? ?? 0;
              if (currentTaskIndex < tasks.length) {
                final currentTask = tasks[currentTaskIndex];
                final playerStatuses = <String, Map<String, dynamic>>{};
                for (final player in game['players'] as List) {
                  final playerId = player['userId'] as String;
                  playerStatuses[playerId] = {
                    'state': 'not_started',
                    'videoUrl': null,
                    'textAnswer': null,
                    'score': null,
                    'submittedAt': null,
                  };
                }
                currentTask['playerStatuses'] = playerStatuses;
                currentTask['status'] = 'waiting_for_submissions';
                currentTask['deadline'] = DateTime.now()
                    .add(Duration(hours: game['settings']['taskDeadlineHours'] as int))
                    .toIso8601String();
                tasks[currentTaskIndex] = currentTask;
                updates['tasks'] = tasks;
              }
            }
          }
        }
      }

      _games[gameIndex] = {...game, ...updates};
      _gamesController.add(List.from(_games));

      // Update individual game stream if it exists
      if (_gameControllers.containsKey(gameId)) {
        _gameControllers[gameId]!.add(_games[gameIndex]);
      }
    }
  }

  @override
  Future<void> deleteGame(String gameId) async {
    // Simulate realistic network delay (300ms-1s)
    await Future.delayed(Duration(milliseconds: 300 + _random.nextInt(700)));

    _games.removeWhere((game) => game['id'] == gameId);
    _gamesController.add(List.from(_games));

    // Close individual game stream if it exists
    if (_gameControllers.containsKey(gameId)) {
      _gameControllers[gameId]!.add(null);
      _gameControllers[gameId]!.close();
      _gameControllers.remove(gameId);
    }
  }

  @override
  Stream<Map<String, dynamic>?> getGameStream(String gameId) async* {
    print('[MockGameDataSource] getGameStream called for gameId: $gameId');
    print('[MockGameDataSource] Available game IDs: ${_games.map((g) => g['id']).toList()}');

    // Find and emit initial data immediately
    final game = _games.firstWhere(
      (game) => game['id'] == gameId,
      orElse: () => {},
    );

    print('[MockGameDataSource] Found game: ${game.isNotEmpty ? game['gameName'] : 'null'}');

    if (game.isNotEmpty) {
      yield game;
    } else {
      yield null;
    }

    // Set up controller for future updates if not exists
    if (!_gameControllers.containsKey(gameId)) {
      _gameControllers[gameId] = StreamController<Map<String, dynamic>?>.broadcast();
    }

    // Yield all future updates from the controller
    await for (final updatedGame in _gameControllers[gameId]!.stream) {
      yield updatedGame;
    }
  }

  @override
  Future<String> joinGame(String inviteCode, String userId) async {
    // Simulate realistic network delay (400ms-1.2s)
    await Future.delayed(Duration(milliseconds: 400 + _random.nextInt(800)));

    final game = _games.firstWhere(
      (game) => game['inviteCode'] == inviteCode,
      orElse: () => {},
    );

    if (game.isEmpty) {
      throw Exception('Game not found with invite code: $inviteCode');
    }

    // Check if user is already in the game
    final players = List<Map<String, dynamic>>.from(game['players']);
    final isAlreadyInGame = players.any((player) => player['userId'] == userId);

    if (!isAlreadyInGame) {
      // Check max players limit
      final settings = game['settings'] as Map<String, dynamic>?;
      final maxPlayers = settings?['maxPlayers'] as int? ?? 10;
      if (players.length >= maxPlayers) {
        throw Exception('Game is full (max $maxPlayers players)');
      }

      players.add({
        'userId': userId,
        'displayName': 'Player ${userId.substring(0, 8)}',
        'totalScore': 0,
      });

      game['players'] = players;
      _gamesController.add(List.from(_games));

      // Update individual game stream if it exists
      if (_gameControllers.containsKey(game['id'])) {
        _gameControllers[game['id']]!.add(game);
      }
    }

    return game['id'] as String;
  }

  void dispose() {
    _gamesController.close();
    for (final controller in _gameControllers.values) {
      controller.close();
    }
    _gameControllers.clear();
  }
}