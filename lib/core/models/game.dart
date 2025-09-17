import 'package:equatable/equatable.dart';
import 'player.dart';
import 'task.dart';

enum GameStatus { lobby, inProgress, completed }

class Game extends Equatable {
  final String id;
  final String gameName;
  final String creatorId;
  final String judgeId;
  final GameStatus status;
  final String inviteCode;
  final DateTime createdAt;
  final List<Player> players;
  final List<Task> tasks;

  const Game({
    required this.id,
    required this.gameName,
    required this.creatorId,
    required this.judgeId,
    required this.status,
    required this.inviteCode,
    required this.createdAt,
    required this.players,
    required this.tasks,
  });

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      id: map['id'] as String,
      gameName: map['gameName'] as String,
      creatorId: map['creatorId'] as String,
      judgeId: map['judgeId'] as String,
      status: GameStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => GameStatus.lobby,
      ),
      inviteCode: map['inviteCode'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      players: (map['players'] as List<dynamic>?)
          ?.map((e) => Player.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      tasks: (map['tasks'] as List<dynamic>?)
          ?.map((e) => Task.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gameName': gameName,
      'creatorId': creatorId,
      'judgeId': judgeId,
      'status': status.name,
      'inviteCode': inviteCode,
      'createdAt': createdAt.toIso8601String(),
      'players': players.map((e) => e.toMap()).toList(),
      'tasks': tasks.map((e) => e.toMap()).toList(),
    };
  }

  Game copyWith({
    String? id,
    String? gameName,
    String? creatorId,
    String? judgeId,
    GameStatus? status,
    String? inviteCode,
    DateTime? createdAt,
    List<Player>? players,
    List<Task>? tasks,
  }) {
    return Game(
      id: id ?? this.id,
      gameName: gameName ?? this.gameName,
      creatorId: creatorId ?? this.creatorId,
      judgeId: judgeId ?? this.judgeId,
      status: status ?? this.status,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
      players: players ?? this.players,
      tasks: tasks ?? this.tasks,
    );
  }

  bool get isInLobby => status == GameStatus.lobby;
  bool get isInProgress => status == GameStatus.inProgress;
  bool get isCompleted => status == GameStatus.completed;

  Player? getPlayerById(String userId) {
    try {
      return players.firstWhere((player) => player.userId == userId);
    } catch (e) {
      return null;
    }
  }

  bool isUserInGame(String userId) {
    return players.any((player) => player.userId == userId);
  }

  bool isUserCreator(String userId) {
    return creatorId == userId;
  }

  bool isUserJudge(String userId) {
    return judgeId == userId;
  }

  @override
  List<Object> get props => [
        id,
        gameName,
        creatorId,
        judgeId,
        status,
        inviteCode,
        createdAt,
        players,
        tasks,
      ];
}