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
      'players': [],
      'tasks': [],
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
    final game = await remoteDataSource.getGame(gameId);

    if (game == null) {
      throw Exception('Game not found');
    }

    // Validate game can be started
    if (game.players.length < 2) {
      throw Exception('Need at least 2 players to start');
    }

    if (game.tasks.isEmpty) {
      throw Exception('Need at least 1 task to start');
    }

    // Initialize playerStatuses for all tasks
    final updatedTasks = game.tasks.map((task) {
      final playerStatuses = <String, PlayerTaskStatus>{};

      for (final player in game.players) {
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
    if (game.settings.taskDeadlineHours != null) {
      firstTaskDeadline = DateTime.now().add(
        Duration(hours: game.settings.taskDeadlineHours!),
      );
    }

    // Update first task with deadline
    if (updatedTasks.isNotEmpty && firstTaskDeadline != null) {
      updatedTasks[0] = updatedTasks[0].copyWith(deadline: firstTaskDeadline);
    }

    // Update game to in-progress with initialized tasks
    final updatedGame = game.copyWith(
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
  Future<void> judgeSubmission(String gameId, String taskId, String submissionId, int score) async {
    // This would update the submission with the judge's score
    // Complex update operation for nested data
  }

  String _generateInviteCode() {
    // Generate a 6-character alphanumeric code
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(6, (index) => chars[random % chars.length]).join();
  }
}