import 'package:flutter_test/flutter_test.dart';
import 'package:taskcaster_app/core/models/telephone_session.dart';
import 'package:taskcaster_app/features/telephone/data/datasources/mock_telephone_data_source.dart';
import 'package:taskcaster_app/features/telephone/data/repositories/telephone_repository_impl.dart';

/// Read the current persisted state of a session straight off the mock data
/// source (first value of its watch stream).
Future<TelephoneSession> _read(
        TelephoneRepositoryImpl repo, String sessionId) async =>
    (await repo.watchSession(sessionId).first)!;

void main() {
  late MockTelephoneDataSource ds;
  late TelephoneRepositoryImpl repo;

  setUp(() {
    ds = MockTelephoneDataSource();
    repo = TelephoneRepositoryImpl(ds);
  });

  tearDown(() => ds.dispose());

  group('createSession', () {
    test('returns the session id and invite code, and makes creator the host',
        () async {
      final result = await repo.createSession(
        creatorUid: 'host-1',
        creatorName: 'Sage',
      );
      expect(result.sessionId, isNotEmpty);
      expect(result.inviteCode, hasLength(6));

      final session = await _read(repo, result.sessionId);
      expect(session.creatorUid, 'host-1');
      expect(session.players.single.uid, 'host-1');
      expect(session.inviteCode, result.inviteCode);
    });
  });

  group('resume / dedupe', () {
    test('rejoining your own code as the same player does not duplicate you',
        () async {
      // Host creates a game.
      final created = await repo.createSession(
        creatorUid: 'host-1',
        creatorName: 'Sage',
      );

      // Simulate the resume path: the start screen re-enters with the SAVED
      // host player id rather than minting a new one. Even if that ever reaches
      // joinSession, the per-session id dedupe keeps the roster intact and the
      // host stays the host.
      final sessionId = await repo.joinSession(
        inviteCode: created.inviteCode,
        uid: 'host-1',
        displayName: 'Sage',
      );

      final session = await _read(repo, sessionId);
      expect(session.playerCount, 1, reason: 'no duplicate "Sage" added');
      expect(session.creatorUid, 'host-1', reason: 'host stays host');
    });

    test('a genuinely new player joining adds exactly one player', () async {
      final created = await repo.createSession(
        creatorUid: 'host-1',
        creatorName: 'Sage',
      );
      await repo.joinSession(
        inviteCode: created.inviteCode,
        uid: 'guest-1',
        displayName: 'Robin',
      );
      // And joining AGAIN with that same guest id is idempotent.
      await repo.joinSession(
        inviteCode: created.inviteCode,
        uid: 'guest-1',
        displayName: 'Robin',
      );

      final session = await _read(repo, created.sessionId);
      expect(session.playerCount, 2);
      expect(session.players.map((p) => p.uid),
          containsAll(<String>['host-1', 'guest-1']));
    });
  });

  group('removePlayer', () {
    test('drops the targeted player from the session', () async {
      final created = await repo.createSession(
        creatorUid: 'host-1',
        creatorName: 'Sage',
      );
      await repo.joinSession(
        inviteCode: created.inviteCode,
        uid: 'guest-1',
        displayName: 'Robin',
      );

      await repo.removePlayer(sessionId: created.sessionId, uid: 'guest-1');

      final session = await _read(repo, created.sessionId);
      expect(session.playerCount, 1);
      expect(session.hasPlayer('guest-1'), isFalse);
      expect(session.hasPlayer('host-1'), isTrue);
    });

    test('removing the host is a no-op', () async {
      final created = await repo.createSession(
        creatorUid: 'host-1',
        creatorName: 'Sage',
      );
      await repo.removePlayer(sessionId: created.sessionId, uid: 'host-1');

      final session = await _read(repo, created.sessionId);
      expect(session.playerCount, 1);
      expect(session.hasPlayer('host-1'), isTrue);
    });
  });
}
