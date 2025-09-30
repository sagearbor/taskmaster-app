import 'package:equatable/equatable.dart';
import 'player.dart';
import 'task.dart';
import 'game_settings.dart';

enum GameStatus { lobby, inProgress, completed }

enum GameMode {
  async, // Players submit when ready (primary use case)
  same_device, // Pass phone around (future)
  live, // All online simultaneously (future)
}

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

  // NEW: Async game fields
  final GameMode mode;
  final GameSettings settings;
  final int currentTaskIndex; // Which task is currently active

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
    this.mode = GameMode.async,
    required this.settings,
    this.currentTaskIndex = 0,
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
      mode: GameMode.values.firstWhere(
        (e) => e.name == map['mode'],
        orElse: () => GameMode.async,
      ),
      settings: map['settings'] != null
          ? GameSettings.fromMap(map['settings'] as Map<String, dynamic>)
          : GameSettings.quickPlay(),
      currentTaskIndex: map['currentTaskIndex'] as int? ?? 0,
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
      'mode': mode.name,
      'settings': settings.toMap(),
      'currentTaskIndex': currentTaskIndex,
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
    GameMode? mode,
    GameSettings? settings,
    int? currentTaskIndex,
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
      mode: mode ?? this.mode,
      settings: settings ?? this.settings,
      currentTaskIndex: currentTaskIndex ?? this.currentTaskIndex,
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

  // NEW: Async game computed properties
  Task? get currentTask {
    if (currentTaskIndex >= 0 && currentTaskIndex < tasks.length) {
      return tasks[currentTaskIndex];
    }
    return null;
  }

  bool get hasMoreTasks => currentTaskIndex < tasks.length - 1;

  bool get allTasksCompleted =>
      tasks.isNotEmpty && tasks.every((task) => task.isCompleted);

  int get completedTasksCount =>
      tasks.where((task) => task.isCompleted).length;

  double get progressPercentage {
    if (tasks.isEmpty) return 0.0;
    return (completedTasksCount / tasks.length) * 100;
  }

  // Check if game can be started
  bool get canStart {
    return isInLobby && players.length >= 2 && tasks.isNotEmpty;
  }

  // Check if game is ready for next task
  bool get canAdvanceToNextTask {
    return currentTask != null &&
           currentTask!.isCompleted &&
           hasMoreTasks;
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
        mode,
        settings,
        currentTaskIndex,
      ];
}