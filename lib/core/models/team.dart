import 'package:equatable/equatable.dart';

class Team extends Equatable {
  final String id;
  final String name;
  final String color;
  final List<String> playerIds;
  final int totalScore;

  const Team({
    required this.id,
    required this.name,
    required this.color,
    required this.playerIds,
    required this.totalScore,
  });

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['id'] as String,
      name: map['name'] as String,
      color: map['color'] as String,
      playerIds: List<String>.from(map['playerIds'] as List),
      totalScore: map['totalScore'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'playerIds': playerIds,
      'totalScore': totalScore,
    };
  }

  Team copyWith({
    String? id,
    String? name,
    String? color,
    List<String>? playerIds,
    int? totalScore,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      playerIds: playerIds ?? this.playerIds,
      totalScore: totalScore ?? this.totalScore,
    );
  }

  bool hasPlayer(String playerId) {
    return playerIds.contains(playerId);
  }

  int get playerCount => playerIds.length;

  @override
  List<Object> get props => [id, name, color, playerIds, totalScore];
}