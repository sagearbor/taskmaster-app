import 'dart:math';

import 'package:uuid/uuid.dart';

import '../../../../core/models/telephone_session.dart';
import '../../domain/repositories/telephone_repository.dart';
import '../datasources/telephone_remote_data_source.dart';

class TelephoneRepositoryImpl implements TelephoneRepository {
  final TelephoneRemoteDataSource remoteDataSource;
  final Uuid _uuid = const Uuid();
  final Random _rng = Random();

  TelephoneRepositoryImpl(this.remoteDataSource);

  @override
  Stream<TelephoneSession?> watchSession(String sessionId) {
    return remoteDataSource.watchSession(sessionId).map(
          (data) => data == null ? null : TelephoneSession.fromMap(data),
        );
  }

  @override
  Future<String> createSession({
    required String creatorUid,
    required String creatorName,
    String? gameName,
  }) async {
    final id = _uuid.v4();
    final session = TelephoneSession.create(
      id: id,
      gameName: (gameName == null || gameName.trim().isEmpty)
          ? 'Drawing Telephone'
          : gameName.trim(),
      inviteCode: _generateInviteCode(),
      creatorUid: creatorUid,
      creatorName: creatorName,
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
      final session = TelephoneSession.fromMap(current);
      if (!session.isInLobby) {
        throw Exception('This game has already started');
      }
      if (session.playerCount >= 8 && !session.hasPlayer(uid)) {
        throw Exception('This game is full (8 players max)');
      }
      return session.withPlayerJoined(uid, displayName).toMap();
    });

    return sessionId;
  }

  @override
  Future<void> startGame(String sessionId) async {
    await remoteDataSource.updateSession(sessionId, (current) {
      final session = TelephoneSession.fromMap(current);
      return session.started().toMap();
    });
  }

  @override
  Future<void> submitEntry({
    required String sessionId,
    required String uid,
    required String content,
  }) async {
    await remoteDataSource.updateSession(sessionId, (current) {
      final session = TelephoneSession.fromMap(current);
      return session.withSubmission(uid, content).toMap();
    });
  }

  /// 6 readable chars (ambiguous look-alikes dropped), matching the games
  /// feature's invite-code style.
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[_rng.nextInt(chars.length)]).join();
  }
}
