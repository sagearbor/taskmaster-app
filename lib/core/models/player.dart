import 'package:equatable/equatable.dart';

class Player extends Equatable {
  final String userId;
  final String displayName;
  final int totalScore;

  const Player({
    required this.userId,
    required this.displayName,
    required this.totalScore,
  });

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      userId: map['userId'] as String,
      displayName: map['displayName'] as String,
      totalScore: map['totalScore'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'totalScore': totalScore,
    };
  }

  Player copyWith({
    String? userId,
    String? displayName,
    int? totalScore,
  }) {
    return Player(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      totalScore: totalScore ?? this.totalScore,
    );
  }

  @override
  List<Object> get props => [userId, displayName, totalScore];
}