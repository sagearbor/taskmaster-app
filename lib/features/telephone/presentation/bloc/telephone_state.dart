part of 'telephone_bloc.dart';

enum TelephoneStatus { initial, loading, loaded, error }

class TelephoneState extends Equatable {
  final TelephoneStatus status;
  final TelephoneSession? session;

  /// Transient action error (e.g. a failed submit). The live [session] is kept
  /// so the UI never blanks out; the screen surfaces this via a SnackBar.
  final String? error;

  const TelephoneState({
    required this.status,
    this.session,
    this.error,
  });

  const TelephoneState.initial()
      : status = TelephoneStatus.initial,
        session = null,
        error = null;

  TelephoneState copyWith({
    TelephoneStatus? status,
    TelephoneSession? session,
    String? error,
    bool clearError = false,
  }) {
    return TelephoneState(
      status: status ?? this.status,
      session: session ?? this.session,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, session, error];
}
