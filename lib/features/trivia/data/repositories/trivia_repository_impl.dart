import 'dart:math';

import 'package:uuid/uuid.dart';

import '../../../../core/models/trivia_questions.dart';
import '../../../../core/models/trivia_session.dart';
import '../../domain/repositories/trivia_repository.dart';
import '../datasources/trivia_remote_data_source.dart';

class TriviaRepositoryImpl implements TriviaRepository {
  final TriviaRemoteDataSource remoteDataSource;
  final Uuid _uuid = const Uuid();
  final Random _rng = Random();

  TriviaRepositoryImpl(this.remoteDataSource);

  @override
  Stream<TriviaSession?> watchSession(String sessionId) {
    return remoteDataSource.watchSession(sessionId).map(
          (data) => data == null ? null : TriviaSession.fromMap(data),
        );
  }

  @override
  Future<String> createSession({
    required String creatorUid,
    required String creatorName,
    String? gameName,
    int questionCount = TriviaSession.defaultQuestionCount,
  }) async {
    final id = _uuid.v4();
    final session = TriviaSession.create(
      id: id,
      gameName: (gameName == null || gameName.trim().isEmpty)
          ? 'Trivia Buzzer'
          : gameName.trim(),
      inviteCode: _generateInviteCode(),
      creatorUid: creatorUid,
      creatorName: creatorName,
      questionIds: _pickQuestions(questionCount),
    );
    await remoteDataSource.createSession(session.toMap());
    return id;
  }

  @override
  Future<String> joinSession({
    required String inviteCode,
    required String uid,
    required String displayName,
  }) async {
    final sessionId =
        await remoteDataSource.findSessionIdByCode(inviteCode.toUpperCase());
    if (sessionId == null) {
      throw Exception('Game not found with invite code: $inviteCode');
    }

    await remoteDataSource.updateSession(sessionId, (current) {
      final session = TriviaSession.fromMap(current);
      if (!session.isInLobby) {
        throw Exception('This game has already started');
      }
      if (session.playerCount >= 12 && !session.hasPlayer(uid)) {
        throw Exception('This game is full (12 players max)');
      }
      return session.withPlayerJoined(uid, displayName).toMap();
    });

    return sessionId;
  }

  @override
  Future<void> startGame(String sessionId) async {
    await remoteDataSource.updateSession(sessionId, (current) {
      return TriviaSession.fromMap(current).started().toMap();
    });
  }

  @override
  Future<void> buzz({
    required String sessionId,
    required String uid,
    required int choiceIndex,
    int? atMillis,
  }) async {
    final stamp = atMillis ?? DateTime.now().millisecondsSinceEpoch;
    await remoteDataSource.updateSession(sessionId, (current) {
      return TriviaSession.fromMap(current)
          .withBuzz(uid, choiceIndex, stamp)
          .toMap();
    });
  }

  @override
  Future<void> reveal(String sessionId) async {
    await remoteDataSource.updateSession(sessionId, (current) {
      return TriviaSession.fromMap(current).revealed().toMap();
    });
  }

  @override
  Future<void> advanceQuestion(String sessionId) async {
    await remoteDataSource.updateSession(sessionId, (current) {
      return TriviaSession.fromMap(current).advanceQuestion().toMap();
    });
  }

  /// Choose [count] distinct questions from the bundled bank, shuffled. Clamped
  /// to what the bank actually has so we never ask for more than exist.
  List<String> _pickQuestions(int count) {
    final ids = kTriviaQuestions.map((q) => q.id).toList()..shuffle(_rng);
    final n = count.clamp(1, ids.length);
    return ids.take(n).toList();
  }

  /// 6 readable chars (ambiguous look-alikes dropped), matching the other
  /// games' invite-code style.
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[_rng.nextInt(chars.length)]).join();
  }
}
