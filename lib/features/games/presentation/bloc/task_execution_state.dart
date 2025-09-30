import 'package:equatable/equatable.dart';
import '../../../../core/models/task.dart';
import '../../../../core/models/player_task_status.dart';

abstract class TaskExecutionState extends Equatable {
  const TaskExecutionState();

  @override
  List<Object?> get props => [];
}

class TaskExecutionInitial extends TaskExecutionState {}

class TaskExecutionLoading extends TaskExecutionState {}

class TaskExecutionLoaded extends TaskExecutionState {
  final Task task;
  final PlayerTaskStatus? userStatus;
  final Map<String, PlayerTaskStatus> allPlayerStatuses;
  final int taskNumber; // e.g., "Task 2 of 5"
  final int totalTasks;

  const TaskExecutionLoaded({
    required this.task,
    this.userStatus,
    required this.allPlayerStatuses,
    required this.taskNumber,
    required this.totalTasks,
  });

  bool get hasUserSubmitted => userStatus?.hasSubmitted ?? false;
  bool get canUserViewVideos => userStatus?.canViewVideos ?? false;

  int get submittedCount =>
      allPlayerStatuses.values.where((s) => s.hasSubmitted).length;
  int get totalPlayers => allPlayerStatuses.length;

  @override
  List<Object?> get props => [
        task,
        userStatus,
        allPlayerStatuses,
        taskNumber,
        totalTasks,
      ];
}

class TaskExecutionSubmitted extends TaskExecutionState {
  final String gameId;
  final int taskIndex;

  const TaskExecutionSubmitted({
    required this.gameId,
    required this.taskIndex,
  });

  @override
  List<Object> get props => [gameId, taskIndex];
}

class TaskExecutionError extends TaskExecutionState {
  final String message;

  const TaskExecutionError({required this.message});

  @override
  List<Object> get props => [message];
}