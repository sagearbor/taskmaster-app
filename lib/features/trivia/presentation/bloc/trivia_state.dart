part of 'trivia_bloc.dart';

enum TriviaStatus { initial, loading, loaded, error }

class TriviaState extends Equatable {
  final TriviaStatus status;
  final TriviaSession? session;

  /// Transient action error (e.g. a failed buzz). The live [session] is kept so
  /// the UI never blanks out; the screen surfaces this via a SnackBar.
  final String? error;

  const TriviaState({
    required this.status,
    this.session,
    this.error,
  });

  const TriviaState.initial()
      : status = TriviaStatus.initial,
        session = null,
        error = null;

  TriviaState copyWith({
    TriviaStatus? status,
    TriviaSession? session,
    String? error,
    bool clearError = false,
  }) {
    return TriviaState(
      status: status ?? this.status,
      session: session ?? this.session,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, session, error];
}
