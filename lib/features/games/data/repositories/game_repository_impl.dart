import 'package:uuid/uuid.dart';

import '../../../../core/models/game.dart';
import '../../../../core/models/player.dart';
import '../../../../core/models/player_task_status.dart';
import '../../../../core/models/submission.dart';
import '../../../../core/models/task.dart';
import '../../domain/repositories/game_repository.dart';
import '../datasources/game_remote_data_source.dart';

class GameRepositoryImpl implements GameRepository {
  final GameRemoteDataSource remoteDataSource;
  final Uuid _uuid = const Uuid();

  GameRepositoryImpl(this.remoteDataSource);

  @override
  Stream<List<Game>> getGamesStream() {
    return remoteDataSource.getGamesStream().map(
      (gameDataList) => gameDataList.map((data) => Game.fromMap(data)).toList(),
    );
  }

  @override
  Future<String> createGame(String gameName, String creatorId, String judgeId) async {
    final gameData = {
      'id': _uuid.v4(),
      'gameName': gameName,
      'creatorId': creatorId,
      'judgeId': judgeId,
      'status': GameStatus.lobby.name,
      'inviteCode': _generateInviteCode(),
      'createdAt': DateTime.now().toIso8601String(),
      'players': [
        {
          'userId': creatorId,
          'displayName': 'Creator', // Will be updated with actual name
          'totalScore': 0,
        }
      ],
      'tasks': [],
      // Add missing required fields
      'mode': GameMode.async.name,
      'settings': {
        'taskDeadlineHours': null,
        'autoAdvanceEnabled': true,
        'allowLateSubmissions': false,
        'taskDeadline': null,
      },
      'currentTaskIndex': 0,
    };

    return await remoteDataSource.createGame(gameData);
  }

  @override
  Future<void> updateGame(String gameId, Game game) async {
    await remoteDataSource.updateGame(gameId, game.toMap());
  }

  @override
  Future<void> deleteGame(String gameId) async {
    await remoteDataSource.deleteGame(gameId);
  }

  @override
  Stream<Game?> getGameStream(String gameId) {
    return remoteDataSource.getGameStream(gameId).map(
      (data) => data != null ? Game.fromMap(data) : null,
    );
  }

  @override
  Future<String> joinGame(String inviteCode, String userId, String displayName) async {
    final gameId = await remoteDataSource.joinGame(inviteCode, userId);
    
    // Add player to the game (this would be handled in the data source in real implementation)
    // For now, return the game ID
    return gameId;
  }

  @override
  Future<void> startGame(String gameId) async {
    // Load the current game state
    final game = await remoteDataSource.getGameStream(gameId).first;

    if (game == null) {
      throw Exception('Game not found');
    }

    // Convert from map to Game object
    final gameObj = Game.fromMap({...game, 'id': gameId});

    // Validate game can be started
    if (gameObj.players.isEmpty) {
      throw Exception('Need at least 1 player to start');
    }

    if (gameObj.tasks.isEmpty) {
      throw Exception('Need at least 1 task to start');
    }

    // Initialize playerStatuses for all tasks
    final updatedTasks = gameObj.tasks.map((task) {
      final playerStatuses = <String, PlayerTaskStatus>{};

      for (final player in gameObj.players) {
        playerStatuses[player.userId] = PlayerTaskStatus(
          playerId: player.userId,
          state: TaskPlayerState.not_started,
        );
      }

      return task.copyWith(
        playerStatuses: playerStatuses,
        status: TaskStatus.waiting_for_submissions,
      );
    }).toList();

    // Calculate deadline for first task (if settings specify)
    DateTime? firstTaskDeadline;
    if (gameObj.settings.taskDeadline != null) {
      firstTaskDeadline = DateTime.now().add(gameObj.settings.taskDeadline!);
    }

    // Update first task with deadline
    if (updatedTasks.isNotEmpty && firstTaskDeadline != null) {
      updatedTasks[0] = updatedTasks[0].copyWith(deadline: firstTaskDeadline);
    }

    // Update game to in-progress with initialized tasks
    final updatedGame = gameObj.copyWith(
      status: GameStatus.inProgress,
      tasks: updatedTasks,
      currentTaskIndex: 0,
    );

    await updateGame(gameId, updatedGame);
  }

  @override
  Future<void> addTasksToGame(String gameId, List<String> taskIds) async {
    // This would fetch tasks from task repository and add them to the game
    // Implementation depends on task management system
  }

  @override
  Future<void> submitTaskAnswer(String gameId, String taskId, Submission submission) async {
    // This would add the submission to the specific task in the game
    // Complex update operation for nested data
  }

  @override
  Future<void> judgeSubmission(String gameId, int taskIndex, String playerId, int score) async {
    // Load current game
    final game = await remoteDataSource.getGameStream(gameId).first;
    if (game == null) {
      throw Exception('Game not found');
    }

    final gameObj = Game.fromMap({...game, 'id': gameId});

    if (taskIndex >= gameObj.tasks.length) {
      throw Exception('Task not found');
    }

    // Update the task's player status with the score
    final updatedTasks = List<Task>.from(gameObj.tasks);
    final task = updatedTasks[taskIndex];

    final updatedPlayerStatuses = Map<String, PlayerTaskStatus>.from(task.playerStatuses);
    final playerStatus = updatedPlayerStatuses[playerId];

    if (playerStatus == null) {
      throw Exception('Player status not found for player: $playerId');
    }

    // Update player status with score
    updatedPlayerStatuses[playerId] = playerStatus.copyWith(
      score: score,
      state: TaskPlayerState.judged,
    );

    // Update task with new player statuses
    updatedTasks[taskIndex] = task.copyWith(
      playerStatuses: updatedPlayerStatuses,
    );

    // Update player's total score
    final updatedPlayers = gameObj.players.map((player) {
      if (player.userId == playerId) {
        return player.copyWith(
          totalScore: player.totalScore + score,
        );
      }
      return player;
    }).toList();

    // Update game with new tasks and players
    final updatedGame = gameObj.copyWith(
      tasks: updatedTasks,
      players: updatedPlayers,
    );

    await updateGame(gameId, updatedGame);
  }

  String _generateInviteCode() {
    // Generate a 6-character alphanumeric code
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(6, (index) => chars[random % chars.length]).join();
  }
}