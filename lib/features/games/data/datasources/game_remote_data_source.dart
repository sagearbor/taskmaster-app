abstract class GameRemoteDataSource {
  Stream<List<Map<String, dynamic>>> getGamesStream();
  Future<String> createGame(Map<String, dynamic> gameData);
  Future<void> updateGame(String gameId, Map<String, dynamic> updates);
  Future<void> deleteGame(String gameId);
  Stream<Map<String, dynamic>?> getGameStream(String gameId);
  Future<String> joinGame(String inviteCode, String userId);
}