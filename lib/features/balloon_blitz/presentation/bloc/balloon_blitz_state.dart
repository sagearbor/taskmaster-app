part of 'balloon_blitz_bloc.dart';

enum BlitzStatus { initial, loading, loaded, error }

/// UI-facing state for a Balloon Blitz race: the latest authoritative session
/// plus a transient error message for action failures.
class BalloonBlitzState extends Equatable {
  final BlitzStatus status;
  final BlitzSession? session;
  final String? error;

  const BalloonBlitzState({
    this.status = BlitzStatus.initial,
    this.session,
    this.error,
  });

  const BalloonBlitzState.initial() : this();

  BalloonBlitzState copyWith({
    BlitzStatus? status,
    BlitzSession? session,
    String? error,
    bool clearError = false,
  }) {
    return BalloonBlitzState(
      status: status ?? this.status,
      session: session ?? this.session,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, session, error];
}
