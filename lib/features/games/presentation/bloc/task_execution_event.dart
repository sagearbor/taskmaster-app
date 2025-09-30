import 'package:equatable/equatable.dart';

abstract class TaskExecutionEvent extends Equatable {
  const TaskExecutionEvent();

  @override
  List<Object?> get props => [];
}

class LoadTask extends TaskExecutionEvent {
  final String gameId;
  final int taskIndex;
  final String userId;

  const LoadTask({
    required this.gameId,
    required this.taskIndex,
    required this.userId,
  });

  @override
  List<Object> get props => [gameId, taskIndex, userId];
}

class StartTask extends TaskExecutionEvent {
  final String gameId;
  final int taskIndex;
  final String userId;

  const StartTask({
    required this.gameId,
    required this.taskIndex,
    required this.userId,
  });

  @override
  List<Object> get props => [gameId, taskIndex, userId];
}

class SubmitTask extends TaskExecutionEvent {
  final String gameId;
  final int taskIndex;
  final String userId;
  final String videoUrl;

  const SubmitTask({
    required this.gameId,
    required this.taskIndex,
    required this.userId,
    required this.videoUrl,
  });

  @override
  List<Object> get props => [gameId, taskIndex, userId, videoUrl];
}

class SkipTask extends TaskExecutionEvent {
  final String gameId;
  final int taskIndex;
  final String userId;

  const SkipTask({
    required this.gameId,
    required this.taskIndex,
    required this.userId,
  });

  @override
  List<Object> get props => [gameId, taskIndex, userId];
}