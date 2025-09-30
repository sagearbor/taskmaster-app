part of 'game_detail_bloc.dart';

abstract class GameDetailEvent extends Equatable {
  const GameDetailEvent();

  @override
  List<Object> get props => [];
}

class LoadGameDetail extends GameDetailEvent {
  final String gameId;

  const LoadGameDetail({required this.gameId});

  @override
  List<Object> get props => [gameId];
}

class StartGame extends GameDetailEvent {
  final String gameId;

  const StartGame({required this.gameId});

  @override
  List<Object> get props => [gameId];
}

class SubmitTaskAnswer extends GameDetailEvent {
  final String gameId;
  final String taskId;
  final Submission submission;

  const SubmitTaskAnswer({
    required this.gameId,
    required this.taskId,
    required this.submission,
  });

  @override
  List<Object> get props => [gameId, taskId, submission];
}

class JudgeSubmission extends GameDetailEvent {
  final String gameId;
  final int taskIndex;
  final String playerId;
  final int score;

  const JudgeSubmission({
    required this.gameId,
    required this.taskIndex,
    required this.playerId,
    required this.score,
  });

  @override
  List<Object> get props => [gameId, taskIndex, playerId, score];
}