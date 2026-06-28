import 'package:flutter_test/flutter_test.dart';
import 'package:taskcaster_app/features/balloon_blitz/domain/entities/blitz_session.dart';

void main() {
  BlitzSession lobbyWith(List<BlitzPlayer> players) => BlitzSession(
        hostId: 'h',
        players: players,
      );

  group('BlitzSession leaderboard ordering', () {
    test('ranks highest score first', () {
      final s = lobbyWith(const [
        BlitzPlayer(id: 'a', name: 'Ann', liveScore: 3),
        BlitzPlayer(id: 'b', name: 'Bob', liveScore: 10),
        BlitzPlayer(id: 'c', name: 'Cy', liveScore: 7),
      ]);

      expect(s.leaderboard.map((p) => p.id).toList(), ['b', 'c', 'a']);
    });

    test('breaks ties by case-insensitive name, then id (stable)', () {
      final s = lobbyWith(const [
        BlitzPlayer(id: 'p2', name: 'zoe', liveScore: 5),
        BlitzPlayer(id: 'p1', name: 'Amy', liveScore: 5),
        BlitzPlayer(id: 'p3', name: 'amy', liveScore: 5),
      ]);

      // Same score → 'Amy'/'amy' before 'zoe'; the two 'amy's break by id.
      expect(s.leaderboard.map((p) => p.id).toList(), ['p1', 'p3', 'p2']);
    });

    test('winner is the leaderboard head', () {
      final s = lobbyWith(const [
        BlitzPlayer(id: 'a', name: 'Ann', liveScore: 2),
        BlitzPlayer(id: 'b', name: 'Bob', liveScore: 9),
      ]);
      expect(s.leaderboard.first.id, 'b');
    });
  });

  group('BlitzSession mutations', () {
    test('withPlayerJoined adds, is idempotent on id, and refreshes name', () {
      var s = BlitzSession.createHost(hostId: 'h', hostName: 'Host');
      s = s.withPlayerJoined('p1', 'Pat');
      s = s.withPlayerJoined('p1', 'Patricia'); // same id again

      expect(s.players.length, 2); // host + p1, no duplicate
      expect(s.players.firstWhere((p) => p.id == 'p1').name, 'Patricia');
    });

    test('withScore updates a known player and ignores unknown ids', () {
      var s = lobbyWith(const [BlitzPlayer(id: 'a', name: 'Ann')]);
      s = s.withScore('a', 12);
      s = s.withScore('ghost', 99); // unknown → ignored

      expect(s.players.single.liveScore, 12);
      expect(s.players.length, 1);
    });

    test('started zeroes scores, marks playing and stamps the start time', () {
      var s = lobbyWith(const [
        BlitzPlayer(id: 'a', name: 'Ann', liveScore: 8),
        BlitzPlayer(id: 'b', name: 'Bob', liveScore: 4),
      ]);
      s = s.started(now: 1234);

      expect(s.phase, BlitzPhase.playing);
      expect(s.startAtEpochMs, 1234);
      expect(s.players.every((p) => p.liveScore == 0), isTrue);
    });

    test('ended freezes to results and is idempotent', () {
      var s = lobbyWith(const []).started(now: 1);
      s = s.ended();
      expect(s.phase, BlitzPhase.results);
      expect(s.ended().phase, BlitzPhase.results);
    });

    test('backToLobby clears scores, phase and start time', () {
      var s = lobbyWith(const [
        BlitzPlayer(id: 'a', name: 'Ann', liveScore: 8),
      ]).started(now: 5).withScore('a', 8).ended();

      s = s.backToLobby();
      expect(s.phase, BlitzPhase.lobby);
      expect(s.startAtEpochMs, isNull);
      expect(s.players.single.liveScore, 0);
    });
  });

  group('BlitzSession serialization', () {
    test('round-trips through toMap/fromMap', () {
      const s = BlitzSession(
        hostId: 'h',
        phase: BlitzPhase.playing,
        startAtEpochMs: 999,
        durationSeconds: 30,
        players: [
          BlitzPlayer(id: 'h', name: 'Host', liveScore: 4, isHost: true),
          BlitzPlayer(id: 'p1', name: 'Pat', liveScore: 7),
        ],
      );

      final restored = BlitzSession.fromMap(s.toMap());
      expect(restored, equals(s));
    });
  });
}
