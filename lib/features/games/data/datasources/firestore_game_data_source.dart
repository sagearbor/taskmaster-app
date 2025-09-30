import 'package:cloud_firestore/cloud_firestore.dart';

import 'game_remote_data_source.dart';

class FirestoreGameDataSource implements GameRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _gamesCollection = 'games';

  @override
  Stream<List<Map<String, dynamic>>> getGamesStream() {
    return _firestore
        .collection(_gamesCollection)
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
    // Remove id if present (Firestore will generate it)
    final data = Map<String, dynamic>.from(gameData);
    final id = data.remove('id');

    // Use provided ID or let Firestore generate one
    if (id != null && id.isNotEmpty) {
      await _firestore.collection(_gamesCollection).doc(id).set(data);
      return id;
    } else {
      final docRef = await _firestore.collection(_gamesCollection).add(data);
      return docRef.id;
    }
  }

  @override
  Future<void> updateGame(String gameId, Map<String, dynamic> updates) async {
    await _firestore.collection(_gamesCollection).doc(gameId).update(updates);
  }

  @override
  Future<void> deleteGame(String gameId) async {
    await _firestore.collection(_gamesCollection).doc(gameId).delete();
  }

  @override
  Stream<Map<String, dynamic>?> getGameStream(String gameId) {
    return _firestore
        .collection(_gamesCollection)
        .doc(gameId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      final data = snapshot.data()!;
      data['id'] = snapshot.id;
      return data;
    });
  }

  @override
  Future<String> joinGame(String inviteCode, String userId) async {
    // Query for game with this invite code
    final querySnapshot = await _firestore
        .collection(_gamesCollection)
        .where('inviteCode', isEqualTo: inviteCode)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('Game not found with invite code: $inviteCode');
    }

    final gameDoc = querySnapshot.docs.first;
    final gameId = gameDoc.id;
    final gameData = gameDoc.data();

    // Check if user is already in the game
    final players = List<Map<String, dynamic>>.from(gameData['players'] ?? []);
    final isAlreadyInGame = players.any((player) => player['userId'] == userId);

    if (!isAlreadyInGame) {
      players.add({
        'userId': userId,
        'displayName': 'Player ${userId.substring(0, 8)}',
        'totalScore': 0,
      });

      await _firestore.collection(_gamesCollection).doc(gameId).update({
        'players': players,
      });
    }

    return gameId;
  }
}