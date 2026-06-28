import 'dart:async';

import '../../domain/entities/blitz_session.dart';
import '../datasources/blitz_transport.dart';

enum BlitzRole { host, peer }

/// The host-authoritative engine for an offline Balloon Blitz race.
///
/// Exactly like the Telephone Nearby repository, the HOST holds the one true
/// [BlitzSession]: it applies the pure model mutations ([BlitzSession.started],
/// [BlitzSession.withScore], [BlitzSession.ended] …) and broadcasts
/// `session.toMap()` to every peer. PEERS never mutate locally — they rebuild
/// the session from each broadcast and send their own actions (join, score) to
/// the host as tiny JSON messages, which the host applies and re-broadcasts.
///
/// Wire protocol (all maps carry a `k` kind):
///  * peer → host  `{'k':'join','id':..,'name':..}`   — announce in the lobby
///  * peer → host  `{'k':'score','id':..,'score':..}` — my latest pop score
///  * host → peers `{'k':'session','session':{…}}`     — full authoritative state
class BalloonBlitzRepository {
  BalloonBlitzRepository._({
    required this.role,
    required this.transport,
    required this.selfId,
    required this.selfName,
    BlitzSession? initialSession,
    int Function()? now,
  })  : _current = initialSession,
        _now = now ?? (() => DateTime.now().millisecondsSinceEpoch) {
    transport.onMessage = _onMessage;
    transport.onEndpointConnected = _onEndpointConnected;
    transport.onEndpointDisconnected = _onEndpointDisconnected;
  }

  /// Create a host that owns [session] (already built with the host in the
  /// lobby). [now] is injectable so round timing is deterministic in tests.
  factory BalloonBlitzRepository.host({
    required BlitzTransport transport,
    required BlitzSession session,
    int Function()? now,
  }) {
    return BalloonBlitzRepository._(
      role: BlitzRole.host,
      transport: transport,
      selfId: session.hostId,
      selfName: session.host?.name ?? 'Host',
      initialSession: session,
      now: now,
    );
  }

  /// Create a peer. [selfId] is this device's per-session player id.
  factory BalloonBlitzRepository.peer({
    required BlitzTransport transport,
    required String selfId,
    required String selfName,
    int Function()? now,
  }) {
    return BalloonBlitzRepository._(
      role: BlitzRole.peer,
      transport: transport,
      selfId: selfId,
      selfName: selfName,
      now: now,
    );
  }

  final BlitzRole role;
  final BlitzTransport transport;
  final String selfId;
  final String selfName;
  final int Function() _now;

  BlitzSession? _current;
  final _controller = StreamController<BlitzSession?>.broadcast();
  Timer? _roundTimer;

  bool get isHost => role == BlitzRole.host;
  BlitzSession? get current => _current;

  // ---- Lobby plumbing ------------------------------------------------------

  /// HOST: start advertising so peers can discover this race.
  Future<bool> startHosting() =>
      transport.startAdvertising("$selfName's Balloon Blitz");

  /// PEER: live list of nearby hosts.
  Stream<List<NearbyDevice>> get discoveredDevices =>
      transport.discoveredDevices;

  /// PEER: start scanning for hosts.
  Future<bool> startDiscovery() => transport.startDiscovery(selfName);

  /// PEER: connect to a chosen host; the first session arrives via [watchSession].
  Future<bool> connect(String endpointId) => transport.connect(endpointId);

  // ---- Live session --------------------------------------------------------

  /// The authoritative session: the current value first, then every update.
  Stream<BlitzSession?> watchSession() async* {
    yield _current;
    yield* _controller.stream;
  }

  // ---- Round lifecycle (host-authoritative) --------------------------------

  /// HOST: begin a synchronized round. Resets every score, marks the session
  /// [BlitzPhase.playing], stamps the start time, broadcasts, and schedules the
  /// authoritative time-up that flips everyone to results.
  Future<void> startRound() async {
    if (!isHost) return;
    final s = _current;
    if (s == null) return;
    _apply(s.started(now: _now()));
    _roundTimer?.cancel();
    _roundTimer = Timer(
      Duration(seconds: s.durationSeconds),
      endRound,
    );
  }

  /// HOST: end the current round and reveal the final ranking. Idempotent and
  /// safe to call from the time-up timer or an early "everyone finished" path.
  void endRound() {
    if (!isHost) return;
    final s = _current;
    if (s == null || s.phase != BlitzPhase.playing) return;
    _roundTimer?.cancel();
    _apply(s.ended());
  }

  /// HOST: drop scores and return to the lobby for another race.
  Future<void> playAgain() async {
    if (!isHost) return;
    _roundTimer?.cancel();
    final s = _current;
    if (s == null) return;
    _apply(s.backToLobby());
  }

  /// Report THIS device's latest local balloon-pop score. The host updates its
  /// own player and re-broadcasts; a peer sends it to the host, which applies
  /// the same mutation — so the leaderboard always converges on the host.
  Future<void> reportLocalScore(int score) async {
    if (isHost) {
      final s = _current;
      if (s == null) return;
      _apply(s.withScore(selfId, score));
    } else {
      await transport.sendToEndpoint(
        _hostEndpoint(),
        {'k': 'score', 'id': selfId, 'score': score},
      );
    }
  }

  // ---- Internals -----------------------------------------------------------

  void _apply(BlitzSession next) {
    _current = next;
    if (!_controller.isClosed) _controller.add(next);
    transport.broadcast({'k': 'session', 'session': next.toMap()});
  }

  String _hostEndpoint() {
    final ids = transport.connectedEndpoints;
    return ids.isEmpty ? '' : ids.first;
  }

  void _onEndpointConnected(String endpointId) {
    if (isHost) {
      // Push the current state to the freshly-connected peer so it renders the
      // lobby immediately, even before its own join is processed.
      final s = _current;
      if (s != null) {
        transport.sendToEndpoint(
            endpointId, {'k': 'session', 'session': s.toMap()});
      }
    } else {
      // We (peer) connected to the host — announce ourselves into the roster.
      transport.sendToEndpoint(
          endpointId, {'k': 'join', 'id': selfId, 'name': selfName});
    }
  }

  void _onEndpointDisconnected(String endpointId) {
    // A drop leaves the player in the roster: the pure model owns no removal
    // rule and yanking someone mid-round would scramble the leaderboard. Lobby
    // drops are a known limitation, matching the Telephone offline flow.
  }

  void _onMessage(String endpointId, Map<String, dynamic> message) {
    final kind = message['k'] as String?;
    if (isHost) {
      final s = _current;
      if (s == null) return;
      switch (kind) {
        case 'join':
          final id = message['id'] as String?;
          final name = message['name'] as String? ?? 'Player';
          if (id != null) _apply(s.withPlayerJoined(id, name));
          break;
        case 'score':
          final id = message['id'] as String?;
          final score = (message['score'] as num?)?.toInt() ?? 0;
          if (id != null) _apply(s.withScore(id, score));
          break;
      }
    } else {
      if (kind == 'session') {
        final raw = message['session'];
        if (raw is Map) {
          _current = BlitzSession.fromMap(Map<String, dynamic>.from(raw));
          if (!_controller.isClosed) _controller.add(_current);
        }
      }
    }
  }

  Future<void> dispose() async {
    _roundTimer?.cancel();
    await transport.dispose();
    if (!_controller.isClosed) await _controller.close();
  }
}
