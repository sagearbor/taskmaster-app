import '../../../../core/models/game.dart';
import '../../../../core/models/submission.dart';
import '../../../../core/models/task.dart';

abstract class GameRepository {
  Stream<List<Game>> getGamesStream();
  Future<String> createGame(String gameName, String creatorId, String judgeId);
  Future<void> updateGame(String gameId, Game game);
  Future<void> deleteGame(String gameId);
  Stream<Game?> getGameStream(String gameId);
  Future<String> joinGame(String inviteCode, String userId, String displayName);
  Future<void> startGame(String gameId);
  Future<void> addTasksToGame(String gameId, List<Task> tasks);
  Future<void> submitTaskAnswer(String gameId, String taskId, Submission submission);
  Future<void> judgeSubmission(String gameId, int taskIndex, String playerId, int score);
}