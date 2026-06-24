import '../../../../core/models/game.dart';
import '../../../../core/models/submission.dart';
import '../../../../core/models/task.dart';

abstract class GameRepository {
  Stream<List<Game>> getGamesStream();

  /// Games marked public — the discoverable community gallery.
  Stream<List<Game>> getPublicGamesStream();

  /// Create a few ready-made public template games owned by [ownerId] so the
  /// gallery has real content to discover. Used to bootstrap an empty gallery.
  Future<void> seedStarterPublicGames(String ownerId, String displayName);

  /// Create a new private game owned by [creatorId] that copies [template]'s
  /// tasks (as fresh, unsubmitted tasks). Returns the new game id.
  Future<String> cloneGame(Game template, String creatorId, String displayName);

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