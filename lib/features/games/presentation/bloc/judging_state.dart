import 'package:equatable/equatable.dart';

import '../../../../core/models/player_task_status.dart';

class SubmissionData {
  final String playerId;
  final String playerName;
  final String? submissionUrl;
  final PlayerTaskStatus status;
  int? score;
  bool skipped;

  SubmissionData({
    required this.playerId,
    required this.playerName,
    required this.submissionUrl,
    required this.status,
    this.score,
    this.skipped = false,
  });
}

abstract class JudgingState extends Equatable {
  const JudgingState();

  @override
  List<Object?> get props => [];
}

class JudgingInitial extends JudgingState {}

class JudgingLoading extends JudgingState {}

class JudgingLoaded extends JudgingState {
  final String gameId;
  final int taskIndex;
  final String taskTitle;
  final String taskDescription;
  final List<SubmissionData> submissions;
  final int currentIndex;
  final Map<String, int> scores;

  const JudgingLoaded({
    required this.gameId,
    required this.taskIndex,
    required this.taskTitle,
    required this.taskDescription,
    required this.submissions,
    required this.currentIndex,
    required this.scores,
  });

  int get totalSubmissions => submissions.length;
  int get submittedCount => submissions.where((s) => s.status.hasSubmitted).length;
  int get scoredCount => scores.length;
  bool get allSubmitted => submittedCount == totalSubmissions;
  bool get allScored => scoredCount == submittedCount;
  bool get canFinish => allScored || scoredCount > 0;

  JudgingLoaded copyWith({
    String? gameId,
    int? taskIndex,
    String? taskTitle,
    String? taskDescription,
    List<SubmissionData>? submissions,
    int? currentIndex,
    Map<String, int>? scores,
  }) {
    return JudgingLoaded(
      gameId: gameId ?? this.gameId,
      taskIndex: taskIndex ?? this.taskIndex,
      taskTitle: taskTitle ?? this.taskTitle,
      taskDescription: taskDescription ?? this.taskDescription,
      submissions: submissions ?? this.submissions,
      currentIndex: currentIndex ?? this.currentIndex,
      scores: scores ?? this.scores,
    );
  }

  @override
  List<Object?> get props => [
        gameId,
        taskIndex,
        taskTitle,
        taskDescription,
        submissions,
        currentIndex,
        scores,
      ];
}

class JudgingCompleted extends JudgingState {
  final String gameId;
  final int taskIndex;

  const JudgingCompleted({
    required this.gameId,
    required this.taskIndex,
  });

  @override
  List<Object?> get props => [gameId, taskIndex];
}

class JudgingError extends JudgingState {
  final String message;

  const JudgingError({required this.message});

  @override
  List<Object?> get props => [message];
}