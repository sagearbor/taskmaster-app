import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'game_remote_data_source.dart';

class FirebaseGameDataSource implements GameRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirebaseGameDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  @override
  Stream<List<Map<String, dynamic>>> getGamesStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      developer.log('No authenticated user, returning empty stream');
      return Stream.value([]);
    }

    developer.log('Getting games stream for user: $userId');

    return _firestore
        .collection('games')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final games = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .where((game) {
            // Filter client-side for games where user is a player
            final players = List.from(game['players'] ?? []);
            return players.any((p) => p['userId'] == userId);
          })
          .toList();

      developer.log('Fetched ${games.length} games');
      return games;
    });
  }

  @override
  Stream<Map<String, dynamic>?> getGameStream(String gameId) {
    developer.log('Getting game stream for gameId: $gameId');

    return _firestore
        .collection('games')
        .doc(gameId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            developer.log('Game $gameId does not exist');
            return null;
          }
          final data = {'id': doc.id, ...doc.data()!};
          developer.log('Game $gameId updated');
          return data;
        });
  }

  @override
  Future<String> createGame(Map<String, dynamic> gameData) async {
    try {
      developer.log('Creating game: ${gameData['gameName']}');

      final docRef = await _firestore.collection('games').add(gameData);

      developer.log('Game created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      developer.log(
        'Error creating game',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateGame(String gameId, Map<String, dynamic> updates) async {
    try {
      developer.log('Updating game $gameId with ${updates.keys.length} fields');

      await _firestore
          .collection('games')
          .doc(gameId)
          .update(updates);

      developer.log('Game $gameId updated successfully');
    } catch (e, stackTrace) {
      developer.log(
        'Error updating game $gameId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteGame(String gameId) async {
    try {
      developer.log('Deleting game $gameId');

      await _firestore
          .collection('games')
          .doc(gameId)
          .delete();

      developer.log('Game $gameId deleted successfully');
    } catch (e, stackTrace) {
      developer.log(
        'Error deleting game $gameId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<String> joinGame(String inviteCode, String userId) async {
    try {
      developer.log('User $userId attempting to join game with code: $inviteCode');

      final query = await _firestore
          .collection('games')
          .where('inviteCode', isEqualTo: inviteCode)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        developer.log('No game found with invite code: $inviteCode');
        throw Exception('Game not found with invite code: $inviteCode');
      }

      final gameDoc = query.docs.first;
      final gameData = gameDoc.data();
      final players = List<Map<String, dynamic>>.from(gameData['players'] ?? []);

      // Check if user already in game
      if (players.any((p) => p['userId'] == userId)) {
        developer.log('User $userId already in game ${gameDoc.id}');
        return gameDoc.id;
      }

      // Get user display name from auth or use default
      final currentUser = _auth.currentUser;
      final displayName = currentUser?.displayName ??
                         currentUser?.email?.split('@')[0] ??
                         'Player ${userId.substring(0, 8)}';

      // Add player
      players.add({
        'userId': userId,
        'displayName': displayName,
        'totalScore': 0,
      });

      await gameDoc.reference.update({'players': players});

      developer.log('User $userId joined game ${gameDoc.id}');
      return gameDoc.id;
    } catch (e, stackTrace) {
      developer.log(
        'Error joining game with code $inviteCode',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> startGame(String gameId) async {
    try {
      developer.log('Starting game $gameId');

      final gameDoc = await _firestore.collection('games').doc(gameId).get();

      if (!gameDoc.exists) {
        throw Exception('Game not found');
      }

      final gameData = gameDoc.data()!;

      // Validation
      final players = List.from(gameData['players'] ?? []);
      final tasks = List.from(gameData['tasks'] ?? []);

      if (players.length < 2) {
        throw Exception('Need at least 2 players to start');
      }
      if (tasks.isEmpty) {
        throw Exception('Need at least 1 task to start');
      }

      // Initialize first task playerStatuses
      final firstTask = Map<String, dynamic>.from(tasks[0]);
      final playerStatuses = <String, Map<String, dynamic>>{};

      for (final player in players) {
        playerStatuses[player['userId']] = {
          'state': 'not_started',
          'videoUrl': null,
          'textAnswer': null,
          'score': null,
          'submittedAt': null,
        };
      }

      firstTask['playerStatuses'] = playerStatuses;
      firstTask['status'] = 'waiting_for_submissions';

      final settings = Map<String, dynamic>.from(gameData['settings'] ?? {});
      final deadlineHours = settings['taskDeadlineHours'] ?? 24;

      firstTask['deadline'] = DateTime.now()
          .add(Duration(hours: deadlineHours))
          .toIso8601String();

      tasks[0] = firstTask;

      // Update game
      await gameDoc.reference.update({
        'status': 'inProgress',
        'currentTaskIndex': 0,
        'tasks': tasks,
      });

      developer.log('Game $gameId started successfully');
    } catch (e, stackTrace) {
      developer.log(
        'Error starting game $gameId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> submitTask(
    String gameId,
    int taskIndex,
    String playerId,
    String videoUrl,
  ) async {
    try {
      developer.log('Player $playerId submitting task $taskIndex for game $gameId');

      final gameDoc = await _firestore.collection('games').doc(gameId).get();

      if (!gameDoc.exists) {
        throw Exception('Game not found');
      }

      final gameData = gameDoc.data()!;
      final tasks = List.from(gameData['tasks']);

      if (taskIndex >= tasks.length) {
        throw Exception('Invalid task index');
      }

      final task = Map<String, dynamic>.from(tasks[taskIndex]);

      // Update playerStatus
      final playerStatuses = Map<String, dynamic>.from(task['playerStatuses'] ?? {});
      playerStatuses[playerId] = {
        'state': 'submitted',
        'videoUrl': videoUrl,
        'textAnswer': null,
        'score': null,
        'submittedAt': DateTime.now().toIso8601String(),
      };

      // Add or update submission
      final submissions = List<Map<String, dynamic>>.from(task['submissions'] ?? []);
      final existingIndex = submissions.indexWhere((s) => s['userId'] == playerId);

      final submission = {
        'id': existingIndex >= 0
            ? submissions[existingIndex]['id']
            : 'sub_${DateTime.now().millisecondsSinceEpoch}',
        'userId': playerId,
        'videoUrl': videoUrl,
        'textAnswer': null,
        'score': null,
        'isJudged': false,
        'submittedAt': DateTime.now().toIso8601String(),
      };

      if (existingIndex >= 0) {
        submissions[existingIndex] = submission;
      } else {
        submissions.add(submission);
      }

      // Check if all players submitted
      final allSubmitted = playerStatuses.values.every(
        (status) => status['state'] == 'submitted' || status['state'] == 'skipped'
      );

      task['playerStatuses'] = playerStatuses;
      task['submissions'] = submissions;
      if (allSubmitted) {
        task['status'] = 'ready_to_judge';
      }

      tasks[taskIndex] = task;

      await gameDoc.reference.update({'tasks': tasks});

      developer.log('Task $taskIndex submitted successfully for player $playerId');
    } catch (e, stackTrace) {
      developer.log(
        'Error submitting task $taskIndex for player $playerId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> scoreSubmission(
    String gameId,
    int taskIndex,
    String playerId,
    int score,
  ) async {
    try {
      developer.log('Scoring submission for player $playerId: $score points');

      final gameDoc = await _firestore.collection('games').doc(gameId).get();

      if (!gameDoc.exists) {
        throw Exception('Game not found');
      }

      final gameData = gameDoc.data()!;

      // Update task
      final tasks = List.from(gameData['tasks']);
      final task = Map<String, dynamic>.from(tasks[taskIndex]);

      final playerStatuses = Map<String, dynamic>.from(task['playerStatuses'] ?? {});
      if (playerStatuses[playerId] != null) {
        playerStatuses[playerId]['score'] = score;
        playerStatuses[playerId]['state'] = 'judged';
      }

      final submissions = List<Map<String, dynamic>>.from(task['submissions'] ?? []);
      final subIndex = submissions.indexWhere((s) => s['userId'] == playerId);
      if (subIndex >= 0) {
        submissions[subIndex]['score'] = score;
        submissions[subIndex]['isJudged'] = true;
      }

      // Check if all judged
      final allJudged = playerStatuses.values.every(
        (status) => status['state'] == 'judged' || status['state'] == 'skipped'
      );

      task['playerStatuses'] = playerStatuses;
      task['submissions'] = submissions;
      if (allJudged) {
        task['status'] = 'completed';
      }

      tasks[taskIndex] = task;

      // Update player total score
      final players = List<Map<String, dynamic>>.from(gameData['players']);
      final playerIndex = players.indexWhere((p) => p['userId'] == playerId);
      if (playerIndex >= 0) {
        players[playerIndex]['totalScore'] =
            (players[playerIndex]['totalScore'] ?? 0) + score;
      }

      await gameDoc.reference.update({
        'tasks': tasks,
        'players': players,
      });

      developer.log('Submission scored successfully for player $playerId');
    } catch (e, stackTrace) {
      developer.log(
        'Error scoring submission for player $playerId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> advanceToNextTask(String gameId) async {
    try {
      developer.log('Advancing game $gameId to next task');

      final gameDoc = await _firestore.collection('games').doc(gameId).get();

      if (!gameDoc.exists) {
        throw Exception('Game not found');
      }

      final gameData = gameDoc.data()!;

      final currentIndex = gameData['currentTaskIndex'] as int;
      final tasks = List.from(gameData['tasks']);

      if (currentIndex >= tasks.length - 1) {
        throw Exception('No more tasks');
      }

      final nextIndex = currentIndex + 1;

      // Initialize next task
      final nextTask = Map<String, dynamic>.from(tasks[nextIndex]);
      final playerStatuses = <String, Map<String, dynamic>>{};

      final players = List.from(gameData['players']);
      for (final player in players) {
        playerStatuses[player['userId']] = {
          'state': 'not_started',
          'videoUrl': null,
          'textAnswer': null,
          'score': null,
          'submittedAt': null,
        };
      }

      nextTask['playerStatuses'] = playerStatuses;
      nextTask['status'] = 'waiting_for_submissions';

      final settings = Map<String, dynamic>.from(gameData['settings'] ?? {});
      final deadlineHours = settings['taskDeadlineHours'] ?? 24;

      nextTask['deadline'] = DateTime.now()
          .add(Duration(hours: deadlineHours))
          .toIso8601String();

      tasks[nextIndex] = nextTask;

      await gameDoc.reference.update({
        'currentTaskIndex': nextIndex,
        'tasks': tasks,
      });

      developer.log('Advanced to task $nextIndex successfully');
    } catch (e, stackTrace) {
      developer.log(
        'Error advancing to next task for game $gameId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> skipTask(
    String gameId,
    int taskIndex,
    String playerId,
  ) async {
    try {
      developer.log('Player $playerId skipping task $taskIndex');

      final gameDoc = await _firestore.collection('games').doc(gameId).get();

      if (!gameDoc.exists) {
        throw Exception('Game not found');
      }

      final gameData = gameDoc.data()!;
      final tasks = List.from(gameData['tasks']);

      if (taskIndex >= tasks.length) {
        throw Exception('Invalid task index');
      }

      final task = Map<String, dynamic>.from(tasks[taskIndex]);

      // Update playerStatus
      final playerStatuses = Map<String, dynamic>.from(task['playerStatuses'] ?? {});
      playerStatuses[playerId] = {
        'state': 'skipped',
        'videoUrl': null,
        'textAnswer': null,
        'score': 0,
        'submittedAt': DateTime.now().toIso8601String(),
      };

      // Check if all players submitted or skipped
      final allDone = playerStatuses.values.every(
        (status) => status['state'] == 'submitted' || status['state'] == 'skipped'
      );

      task['playerStatuses'] = playerStatuses;
      if (allDone) {
        task['status'] = 'ready_to_judge';
      }

      tasks[taskIndex] = task;

      await gameDoc.reference.update({'tasks': tasks});

      developer.log('Task $taskIndex skipped successfully by player $playerId');
    } catch (e, stackTrace) {
      developer.log(
        'Error skipping task $taskIndex for player $playerId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}