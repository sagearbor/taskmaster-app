import 'package:equatable/equatable.dart';

abstract class JudgingEvent extends Equatable {
  const JudgingEvent();

  @override
  List<Object?> get props => [];
}

class LoadSubmissions extends JudgingEvent {
  final String gameId;
  final int taskIndex;

  const LoadSubmissions({
    required this.gameId,
    required this.taskIndex,
  });

  @override
  List<Object?> get props => [gameId, taskIndex];
}

class ScoreSubmission extends JudgingEvent {
  final String playerId;
  final int score;

  const ScoreSubmission({
    required this.playerId,
    required this.score,
  });

  @override
  List<Object?> get props => [playerId, score];
}

class SkipSubmission extends JudgingEvent {
  final String playerId;

  const SkipSubmission({
    required this.playerId,
  });

  @override
  List<Object?> get props => [playerId];
}

class FinishJudging extends JudgingEvent {
  const FinishJudging();
}