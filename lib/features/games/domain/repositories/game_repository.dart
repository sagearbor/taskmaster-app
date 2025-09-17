import '../../../../core/models/game.dart';
import '../../../../core/models/submission.dart';

abstract class GameRepository {
  Stream<List<Game>> getGamesStream();
  Future<String> createGame(String gameName, String creatorId, String judgeId);
  Future<void> updateGame(String gameId, Game game);
  Future<void> deleteGame(String gameId);
  Stream<Game?> getGameStream(String gameId);
  Future<String> joinGame(String inviteCode, String userId, String displayName);
  Future<void> startGame(String gameId);
  Future<void> addTasksToGame(String gameId, List<String> taskIds);
  Future<void> submitTaskAnswer(String gameId, String taskId, Submission submission);
  Future<void> judgeSubmission(String gameId, String taskId, String submissionId, int score);
}