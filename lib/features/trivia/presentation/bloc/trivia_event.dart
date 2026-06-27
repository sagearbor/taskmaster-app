part of 'trivia_bloc.dart';

abstract class TriviaEvent extends Equatable {
  const TriviaEvent();

  @override
  List<Object?> get props => [];
}

/// Start listening to a session's live state.
class TriviaSubscribed extends TriviaEvent {
  final String sessionId;
  const TriviaSubscribed(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

/// Host begins play (reveals the first question).
class TriviaStarted extends TriviaEvent {
  final String sessionId;
  const TriviaStarted(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

/// A player buzzes in with their chosen answer for the current question.
class TriviaBuzzed extends TriviaEvent {
  final String sessionId;
  final String uid;
  final int choiceIndex;

  const TriviaBuzzed({
    required this.sessionId,
    required this.uid,
    required this.choiceIndex,
  });

  @override
  List<Object?> get props => [sessionId, uid, choiceIndex];
}

/// Host reveals the current question's answer now (scores it).
class TriviaRevealed extends TriviaEvent {
  final String sessionId;
  const TriviaRevealed(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

/// Host advances from reveal to the next question (or the final scoreboard).
class TriviaAdvanced extends TriviaEvent {
  final String sessionId;
  const TriviaAdvanced(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}
