import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'game_remote_data_source.dart';

class FirebaseGameDataSource implements GameRemoteDataSource {
  final FirebaseFirestore _firestore;
  final Random _random = Random();

  FirebaseGameDataSource({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<Map<String, dynamic>>> getGamesStream() {
    return _firestore
        .collection('games')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  @override
  Future<String> createGame(Map<String, dynamic> gameData) async {
    try {
      // Generate unique invite code
      gameData['inviteCode'] = _generateUniqueInviteCode();
      gameData['createdAt'] = FieldValue.serverTimestamp();
      
      final docRef = await _firestore.collection('games').add(gameData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create game: $e');
    }
  }

  @override
  Future<void> updateGame(String gameId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('games').doc(gameId).update(updates);
    } catch (e) {
      throw Exception('Failed to update game: $e');
    }
  }

  @override
  Future<void> deleteGame(String gameId) async {
    try {
      await _firestore.collection('games').doc(gameId).delete();
    } catch (e) {
      throw Exception('Failed to delete game: $e');
    }
  }

  @override
  Stream<Map<String, dynamic>?> getGameStream(String gameId) {
    return _firestore
        .collection('games')
        .doc(gameId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      
      final data = snapshot.data()!;
      data['id'] = snapshot.id;
      return data;
    });
  }

  @override
  Future<String> joinGame(String inviteCode, String userId) async {
    try {
      // Find game with invite code
      final gamesQuery = await _firestore
          .collection('games')
          .where('inviteCode', isEqualTo: inviteCode)
          .limit(1)
          .get();

      if (gamesQuery.docs.isEmpty) {
        throw Exception('Game not found with invite code: $inviteCode');
      }

      final gameDoc = gamesQuery.docs.first;
      final gameData = gameDoc.data();
      final gameId = gameDoc.id;

      // Check if game is still in lobby
      if (gameData['status'] != 'lobby') {
        throw Exception('Cannot join game - game has already started');
      }

      // Check if user is already in the game
      final players = List<Map<String, dynamic>>.from(gameData['players'] ?? []);
      final isAlreadyInGame = players.any((player) => player['userId'] == userId);

      if (isAlreadyInGame) {
        return gameId; // User already in game, return game ID
      }

      // Add user to players list
      players.add({
        'userId': userId,
        'displayName': 'Player ${userId.substring(0, 8)}', // Will be updated with real name
        'totalScore': 0,
      });

      // Update game with new player
      await _firestore.collection('games').doc(gameId).update({
        'players': players,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return gameId;
    } catch (e) {
      throw Exception('Failed to join game: $e');
    }
  }

  String _generateUniqueInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (index) => chars[_random.nextInt(chars.length)]).join();
  }

  Future<void> startGame(String gameId) async {
    try {
      await updateGame(gameId, {
        'status': 'inProgress',
      });
    } catch (e) {
      throw Exception('Failed to start game: $e');
    }
  }

  Future<void> completeGame(String gameId) async {
    try {
      await updateGame(gameId, {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to complete game: $e');
    }
  }

  Future<void> addTasksToGame(String gameId, List<Map<String, dynamic>> tasks) async {
    try {
      await updateGame(gameId, {
        'tasks': tasks,
      });
    } catch (e) {
      throw Exception('Failed to add tasks to game: $e');
    }
  }

  Future<void> addPlayerToGame(String gameId, Map<String, dynamic> player) async {
    try {
      await _firestore.collection('games').doc(gameId).update({
        'players': FieldValue.arrayUnion([player]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add player to game: $e');
    }
  }

  Future<void> removePlayerFromGame(String gameId, String userId) async {
    try {
      final gameDoc = await _firestore.collection('games').doc(gameId).get();
      if (!gameDoc.exists) throw Exception('Game not found');

      final gameData = gameDoc.data()!;
      final players = List<Map<String, dynamic>>.from(gameData['players'] ?? []);
      
      players.removeWhere((player) => player['userId'] == userId);

      await updateGame(gameId, {
        'players': players,
      });
    } catch (e) {
      throw Exception('Failed to remove player from game: $e');
    }
  }

  Future<void> submitTaskAnswer(
    String gameId,
    String taskId,
    Map<String, dynamic> submission,
  ) async {
    try {
      final gameDoc = await _firestore.collection('games').doc(gameId).get();
      if (!gameDoc.exists) throw Exception('Game not found');

      final gameData = gameDoc.data()!;
      final tasks = List<Map<String, dynamic>>.from(gameData['tasks'] ?? []);
      
      // Find the task and add submission
      final taskIndex = tasks.indexWhere((task) => task['id'] == taskId);
      if (taskIndex == -1) throw Exception('Task not found');

      final task = Map<String, dynamic>.from(tasks[taskIndex]);
      final submissions = List<Map<String, dynamic>>.from(task['submissions'] ?? []);
      
      // Remove existing submission from this user if any
      submissions.removeWhere((sub) => sub['userId'] == submission['userId']);
      
      // Add new submission
      submissions.add(submission);
      task['submissions'] = submissions;
      tasks[taskIndex] = task;

      await updateGame(gameId, {
        'tasks': tasks,
      });
    } catch (e) {
      throw Exception('Failed to submit task answer: $e');
    }
  }

  Future<void> judgeSubmission(
    String gameId,
    String taskId,
    String submissionId,
    int score,
  ) async {
    try {
      final gameDoc = await _firestore.collection('games').doc(gameId).get();
      if (!gameDoc.exists) throw Exception('Game not found');

      final gameData = gameDoc.data()!;
      final tasks = List<Map<String, dynamic>>.from(gameData['tasks'] ?? []);
      final players = List<Map<String, dynamic>>.from(gameData['players'] ?? []);
      
      // Find the task and submission
      final taskIndex = tasks.indexWhere((task) => task['id'] == taskId);
      if (taskIndex == -1) throw Exception('Task not found');

      final task = Map<String, dynamic>.from(tasks[taskIndex]);
      final submissions = List<Map<String, dynamic>>.from(task['submissions'] ?? []);
      
      final submissionIndex = submissions.indexWhere((sub) => sub['id'] == submissionId);
      if (submissionIndex == -1) throw Exception('Submission not found');

      final submission = Map<String, dynamic>.from(submissions[submissionIndex]);
      final oldScore = submission['score'] ?? 0;
      
      // Update submission
      submission['score'] = score;
      submission['isJudged'] = true;
      submissions[submissionIndex] = submission;
      task['submissions'] = submissions;
      tasks[taskIndex] = task;

      // Update player's total score
      final userId = submission['userId'];
      final playerIndex = players.indexWhere((player) => player['userId'] == userId);
      if (playerIndex != -1) {
        final player = Map<String, dynamic>.from(players[playerIndex]);
        final currentTotal = player['totalScore'] ?? 0;
        player['totalScore'] = currentTotal - oldScore + score;
        players[playerIndex] = player;
      }

      await updateGame(gameId, {
        'tasks': tasks,
        'players': players,
      });
    } catch (e) {
      throw Exception('Failed to judge submission: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getGamesByUser(String userId) async {
    try {
      final gamesQuery = await _firestore
          .collection('games')
          .where('players', arrayContains: {'userId': userId})
          .orderBy('createdAt', descending: true)
          .get();

      return gamesQuery.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get user games: $e');
    }
  }

  Future<bool> isInviteCodeUnique(String inviteCode) async {
    try {
      final gamesQuery = await _firestore
          .collection('games')
          .where('inviteCode', isEqualTo: inviteCode)
          .limit(1)
          .get();

      return gamesQuery.docs.isEmpty;
    } catch (e) {
      return false;
    }
  }
}