import 'package:equatable/equatable.dart';

import 'blitz_player.dart';

export 'blitz_player.dart';

/// The lifecycle of a Balloon Blitz race.
///  * [lobby]   — host advertises, players join, nobody is popping yet.
///  * [playing] — a synchronized round is live; everyone pops in their own AR
///                scene and streams their score to the host.
///  * [results] — time is up; the final ranking is frozen and shown to all.
enum BlitzPhase { lobby, playing, results }

/// The single authoritative state of a Balloon Blitz race, owned by the host
/// and broadcast verbatim to every peer over the offline Nearby transport.
///
/// All mutations are PURE — they return a new [BlitzSession] and never touch the
/// transport — so the host-authoritative logic and the leaderboard ordering are
/// fully unit-testable without a real device or Bluetooth. The host wraps these
/// with a broadcast; peers simply rebuild from [fromMap].
class BlitzSession extends Equatable {
  /// Player id of the host (the authority that owns the round).
  final String hostId;

  /// Everyone in the race, including the host. Insertion order is join order.
  final List<BlitzPlayer> players;

  /// Where we are in the race lifecycle.
  final BlitzPhase phase;

  /// Host wall-clock (epoch ms) of when the current round started, so every
  /// phone can run its local AR countdown roughly in sync. Null in the lobby.
  final int? startAtEpochMs;

  /// Length of a round in seconds (e.g. 45).
  final int durationSeconds;

  const BlitzSession({
    required this.hostId,
    required this.players,
    this.phase = BlitzPhase.lobby,
    this.startAtEpochMs,
    this.durationSeconds = 45,
  });

  /// A brand-new lobby containing just the host.
  factory BlitzSession.createHost({
    required String hostId,
    required String hostName,
    int durationSeconds = 45,
  }) {
    return BlitzSession(
      hostId: hostId,
      durationSeconds: durationSeconds,
      players: [
        BlitzPlayer(id: hostId, name: hostName, isHost: true),
      ],
    );
  }

  bool get isPlaying => phase == BlitzPhase.playing;
  bool get isFinished => phase == BlitzPhase.results;

  /// The host's own player record.
  BlitzPlayer? get host {
    for (final p in players) {
      if (p.id == hostId) return p;
    }
    return null;
  }

  /// Players ranked for display: highest score first, ties broken by name
  /// (case-insensitive) then id so the order is stable and deterministic.
  List<BlitzPlayer> get leaderboard {
    final sorted = [...players];
    sorted.sort((a, b) {
      final byScore = b.liveScore.compareTo(a.liveScore);
      if (byScore != 0) return byScore;
      final byName =
          a.name.toLowerCase().compareTo(b.name.toLowerCase());
      if (byName != 0) return byName;
      return a.id.compareTo(b.id);
    });
    return sorted;
  }

  /// Add a player to the lobby. Idempotent on [id]: re-joining with the same id
  /// just refreshes the name and never creates a duplicate.
  BlitzSession withPlayerJoined(String id, String name) {
    final next = [...players];
    final idx = next.indexWhere((p) => p.id == id);
    if (idx == -1) {
      next.add(BlitzPlayer(id: id, name: name));
    } else {
      next[idx] = next[idx].copyWith(name: name);
    }
    return copyWith(players: next);
  }

  /// Set a player's reported score. Unknown ids are ignored (a late/echoed
  /// message must never resurrect a player who isn't in the roster).
  BlitzSession withScore(String id, int score) {
    final idx = players.indexWhere((p) => p.id == id);
    if (idx == -1) return this;
    final next = [...players];
    next[idx] = next[idx].copyWith(liveScore: score);
    return copyWith(players: next);
  }

  /// Begin a synchronized round: zero every score, mark [playing] and stamp the
  /// start time. [now] is injectable so the lifecycle is deterministic in tests.
  BlitzSession started({required int now}) {
    final reset = players.map((p) => p.copyWith(liveScore: 0)).toList();
    return copyWith(
      players: reset,
      phase: BlitzPhase.playing,
      startAtEpochMs: now,
    );
  }

  /// Freeze the round and reveal the final ranking. Idempotent.
  BlitzSession ended() => copyWith(phase: BlitzPhase.results);

  /// Return to the lobby for another race, clearing scores and the start time.
  BlitzSession backToLobby() {
    final reset = players.map((p) => p.copyWith(liveScore: 0)).toList();
    return BlitzSession(
      hostId: hostId,
      players: reset,
      durationSeconds: durationSeconds,
      phase: BlitzPhase.lobby,
      startAtEpochMs: null,
    );
  }

  BlitzSession copyWith({
    List<BlitzPlayer>? players,
    BlitzPhase? phase,
    int? startAtEpochMs,
    int? durationSeconds,
  }) {
    return BlitzSession(
      hostId: hostId,
      players: players ?? this.players,
      phase: phase ?? this.phase,
      startAtEpochMs: startAtEpochMs ?? this.startAtEpochMs,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  Map<String, dynamic> toMap() => {
        'hostId': hostId,
        'phase': phase.name,
        'startAtEpochMs': startAtEpochMs,
        'durationSeconds': durationSeconds,
        'players': players.map((p) => p.toMap()).toList(),
      };

  factory BlitzSession.fromMap(Map<String, dynamic> map) {
    final rawPlayers = (map['players'] as List<dynamic>? ?? const []);
    return BlitzSession(
      hostId: map['hostId'] as String? ?? '',
      phase: BlitzPhase.values.firstWhere(
        (p) => p.name == map['phase'],
        orElse: () => BlitzPhase.lobby,
      ),
      startAtEpochMs: (map['startAtEpochMs'] as num?)?.toInt(),
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 45,
      players: rawPlayers
          .map((e) => BlitzPlayer.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  @override
  List<Object?> get props =>
      [hostId, players, phase, startAtEpochMs, durationSeconds];
}
