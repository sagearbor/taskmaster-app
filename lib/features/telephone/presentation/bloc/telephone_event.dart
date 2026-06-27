part of 'telephone_bloc.dart';

abstract class TelephoneEvent extends Equatable {
  const TelephoneEvent();

  @override
  List<Object?> get props => [];
}

/// Start listening to a session's live state.
class TelephoneSubscribed extends TelephoneEvent {
  final String sessionId;
  const TelephoneSubscribed(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

/// Creator begins play (locks the roster).
class TelephoneStarted extends TelephoneEvent {
  final String sessionId;
  const TelephoneStarted(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

/// Host removes a player from the lobby (kick).
class TelephonePlayerRemoved extends TelephoneEvent {
  final String sessionId;
  final String uid;

  const TelephonePlayerRemoved({required this.sessionId, required this.uid});

  @override
  List<Object?> get props => [sessionId, uid];
}

/// A player submits the current step's contribution.
class TelephoneEntrySubmitted extends TelephoneEvent {
  final String sessionId;
  final String uid;
  final String content;

  const TelephoneEntrySubmitted({
    required this.sessionId,
    required this.uid,
    required this.content,
  });

  @override
  List<Object?> get props => [sessionId, uid, content];
}
