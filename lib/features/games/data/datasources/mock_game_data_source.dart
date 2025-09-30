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
    final mockGames = [
      {
        'id': 'game_1',
        'gameName': 'Saturday Night Shenanigans',
        'creatorId': 'user_123',
        'judgeId': 'user_456',
        'status': 'lobby',
        'inviteCode': 'PARTY1',
        'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
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
            'submissions': []
          },
          {
            'id': 'task_2',
            'title': 'Wear the most items of clothing',
            'description': 'Put on as many individual items of clothing as possible. Each item must be visible and properly worn.',
            'taskType': 'video',
            'puzzleAnswer': null,
            'submissions': []
          }
        ]
      },
      {
        'id': 'game_2',
        'gameName': 'Family Game Night',
        'creatorId': 'user_789',
        'judgeId': 'user_101',
        'status': 'inProgress',
        'inviteCode': 'FAMILY',
        'createdAt': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        'players': [
          {'userId': 'user_789', 'displayName': 'Charlie', 'totalScore': 15},
          {'userId': 'user_101', 'displayName': 'Diana the Judge', 'totalScore': 0},
          {'userId': 'user_202', 'displayName': 'Eve', 'totalScore': 12},
          {'userId': 'user_303', 'displayName': 'Frank', 'totalScore': 8},
        ],
        'tasks': [
          {
            'id': 'task_3',
            'title': 'Build the tallest tower',
            'description': 'Using only books, build the tallest possible tower that can stand for at least 10 seconds.',
            'taskType': 'video',
            'puzzleAnswer': null,
            'submissions': [
              {
                'id': 'sub_1',
                'userId': 'user_789',
                'videoUrl': 'https://youtube.com/watch?v=fake1',
                'textAnswer': null,
                'score': 5,
                'isJudged': true,
                'submittedAt': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
              },
              {
                'id': 'sub_2',
                'userId': 'user_202',
                'videoUrl': 'https://youtube.com/watch?v=fake2',
                'textAnswer': null,
                'score': 4,
                'isJudged': true,
                'submittedAt': DateTime.now().subtract(const Duration(minutes: 25)).toIso8601String(),
              }
            ]
          }
        ]
      },
      {
        'id': 'game_3',
        'gameName': 'Office Competition',
        'creatorId': 'user_404',
        'judgeId': 'user_505',
        'status': 'completed',
        'inviteCode': 'OFFICE',
        'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'players': [
          {'userId': 'user_404', 'displayName': 'Grace', 'totalScore': 22},
          {'userId': 'user_505', 'displayName': 'Henry the Judge', 'totalScore': 0},
          {'userId': 'user_606', 'displayName': 'Ivy', 'totalScore': 18},
          {'userId': 'user_707', 'displayName': 'Jack', 'totalScore': 25},
        ],
        'tasks': [
          {
            'id': 'task_4',
            'title': 'Draw a self-portrait using only office supplies',
            'description': 'Create a recognizable self-portrait using only items you can find in an office.',
            'taskType': 'video',
            'puzzleAnswer': null,
            'submissions': []
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
    await Future.delayed(const Duration(milliseconds: 500));
    
    _games.add(gameData);
    _gamesController.add(List.from(_games));
    
    return gameData['id'] as String;
  }

  @override
  Future<void> updateGame(String gameId, Map<String, dynamic> updates) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final gameIndex = _games.indexWhere((game) => game['id'] == gameId);
    if (gameIndex != -1) {
      _games[gameIndex] = {..._games[gameIndex], ...updates};
      _gamesController.add(List.from(_games));
      
      // Update individual game stream if it exists
      if (_gameControllers.containsKey(gameId)) {
        _gameControllers[gameId]!.add(_games[gameIndex]);
      }
    }
  }

  @override
  Future<void> deleteGame(String gameId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
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
  Stream<Map<String, dynamic>?> getGameStream(String gameId) {
    if (!_gameControllers.containsKey(gameId)) {
      _gameControllers[gameId] = StreamController<Map<String, dynamic>?>.broadcast();
      
      // Send initial data
      final game = _games.firstWhere(
        (game) => game['id'] == gameId,
        orElse: () => {},
      );
      
      if (game.isNotEmpty) {
        _gameControllers[gameId]!.add(game);
      } else {
        _gameControllers[gameId]!.add(null);
      }
    }
    
    return _gameControllers[gameId]!.stream;
  }

  @override
  Future<String> joinGame(String inviteCode, String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
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