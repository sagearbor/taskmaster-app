import 'package:equatable/equatable.dart';

class GameSettings extends Equatable {
  final Duration? taskDeadline; // How long players have to submit each task
  final bool autoAdvanceTasks; // Auto-unlock next task when current is judged
  final bool allowSkips; // Players can skip tasks
  final int? maxPlayers; // Maximum players allowed (null = unlimited)

  const GameSettings({
    this.taskDeadline,
    this.autoAdvanceTasks = true,
    this.allowSkips = false,
    this.maxPlayers,
  });

  // Default settings for quick play
  factory GameSettings.quickPlay() {
    return const GameSettings(
      taskDeadline: Duration(hours: 24),
      autoAdvanceTasks: true,
      allowSkips: false,
      maxPlayers: 10,
    );
  }

  // Default settings for custom games
  factory GameSettings.custom() {
    return const GameSettings(
      taskDeadline: null, // No deadline
      autoAdvanceTasks: false, // Manual advancement
      allowSkips: true,
      maxPlayers: null, // Unlimited
    );
  }

  factory GameSettings.fromMap(Map<String, dynamic> map) {
    return GameSettings(
      taskDeadline: map['taskDeadlineSeconds'] != null
          ? Duration(seconds: map['taskDeadlineSeconds'] as int)
          : null,
      autoAdvanceTasks: map['autoAdvanceTasks'] as bool? ?? true,
      allowSkips: map['allowSkips'] as bool? ?? false,
      maxPlayers: map['maxPlayers'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskDeadlineSeconds': taskDeadline?.inSeconds,
      'autoAdvanceTasks': autoAdvanceTasks,
      'allowSkips': allowSkips,
      'maxPlayers': maxPlayers,
    };
  }

  GameSettings copyWith({
    Duration? taskDeadline,
    bool? autoAdvanceTasks,
    bool? allowSkips,
    int? maxPlayers,
  }) {
    return GameSettings(
      taskDeadline: taskDeadline ?? this.taskDeadline,
      autoAdvanceTasks: autoAdvanceTasks ?? this.autoAdvanceTasks,
      allowSkips: allowSkips ?? this.allowSkips,
      maxPlayers: maxPlayers ?? this.maxPlayers,
    );
  }

  @override
  List<Object?> get props => [
        taskDeadline,
        autoAdvanceTasks,
        allowSkips,
        maxPlayers,
      ];
}