import 'package:equatable/equatable.dart';

/// One participant in a Balloon Blitz race. Each player pops balloons in their
/// OWN local AR scene; only [liveScore] travels between phones over the offline
/// Nearby transport. The host aggregates every player's score into the shared
/// leaderboard.
class BlitzPlayer extends Equatable {
  /// Per-session identity (a fresh UUID per device), used to address scores.
  final String id;

  /// Display name shown on the leaderboard.
  final String name;

  /// The player's latest reported balloon-pop score for the current round.
  final int liveScore;

  /// True for the device that hosts the lobby and owns the authoritative round.
  final bool isHost;

  const BlitzPlayer({
    required this.id,
    required this.name,
    this.liveScore = 0,
    this.isHost = false,
  });

  BlitzPlayer copyWith({String? name, int? liveScore, bool? isHost}) {
    return BlitzPlayer(
      id: id,
      name: name ?? this.name,
      liveScore: liveScore ?? this.liveScore,
      isHost: isHost ?? this.isHost,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'liveScore': liveScore,
        'isHost': isHost,
      };

  factory BlitzPlayer.fromMap(Map<String, dynamic> map) => BlitzPlayer(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? 'Player',
        liveScore: (map['liveScore'] as num?)?.toInt() ?? 0,
        isHost: map['isHost'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [id, name, liveScore, isHost];
}
