import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/trivia_session.dart';
import '../../domain/repositories/trivia_repository.dart';

part 'trivia_event.dart';
part 'trivia_state.dart';

/// Streams a single Trivia Buzzer session and forwards player / host actions to
/// the repository. Mutations (start/buzz/reveal/advance) are fire-and-forget
/// against the repo — the authoritative state always comes back via the live
/// stream, so every device converges on the same synced document.
class TriviaBloc extends Bloc<TriviaEvent, TriviaState> {
  final TriviaRepository repository;

  TriviaBloc({required this.repository})
      : super(const TriviaState.initial()) {
    on<TriviaSubscribed>(_onSubscribed);
    on<TriviaStarted>(_onStarted);
    on<TriviaBuzzed>(_onBuzzed);
    on<TriviaRevealed>(_onRevealed);
    on<TriviaAdvanced>(_onAdvanced);
  }

  Future<void> _onSubscribed(
    TriviaSubscribed event,
    Emitter<TriviaState> emit,
  ) async {
    emit(state.copyWith(status: TriviaStatus.loading));
    await emit.forEach<TriviaSession?>(
      repository.watchSession(event.sessionId),
      onData: (session) => session == null
          ? state.copyWith(
              status: TriviaStatus.error,
              error: 'This game no longer exists.',
            )
          : state.copyWith(
              status: TriviaStatus.loaded,
              session: session,
              clearError: true,
            ),
      onError: (error, _) =>
          state.copyWith(status: TriviaStatus.error, error: error.toString()),
    );
  }

  Future<void> _onStarted(
    TriviaStarted event,
    Emitter<TriviaState> emit,
  ) async {
    try {
      await repository.startGame(event.sessionId);
    } catch (e) {
      emit(state.copyWith(error: _friendly(e)));
    }
  }

  Future<void> _onBuzzed(
    TriviaBuzzed event,
    Emitter<TriviaState> emit,
  ) async {
    try {
      await repository.buzz(
        sessionId: event.sessionId,
        uid: event.uid,
        choiceIndex: event.choiceIndex,
      );
    } catch (e) {
      emit(state.copyWith(error: _friendly(e)));
    }
  }

  Future<void> _onRevealed(
    TriviaRevealed event,
    Emitter<TriviaState> emit,
  ) async {
    try {
      await repository.reveal(event.sessionId);
    } catch (e) {
      emit(state.copyWith(error: _friendly(e)));
    }
  }

  Future<void> _onAdvanced(
    TriviaAdvanced event,
    Emitter<TriviaState> emit,
  ) async {
    try {
      await repository.advanceQuestion(event.sessionId);
    } catch (e) {
      emit(state.copyWith(error: _friendly(e)));
    }
  }

  String _friendly(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
