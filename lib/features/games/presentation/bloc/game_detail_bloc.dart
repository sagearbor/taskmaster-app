import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/models/game.dart';
import '../../../../core/models/submission.dart';
import '../../domain/repositories/game_repository.dart';

part 'game_detail_event.dart';
part 'game_detail_state.dart';

class GameDetailBloc extends Bloc<GameDetailEvent, GameDetailState> {
  final GameRepository gameRepository;

  GameDetailBloc({required this.gameRepository}) : super(GameDetailInitial()) {
    on<LoadGameDetail>(_onLoadGameDetail);
    on<StartGame>(_onStartGame);
    on<SubmitTaskAnswer>(_onSubmitTaskAnswer);
    on<JudgeSubmission>(_onJudgeSubmission);
  }

  void _onLoadGameDetail(LoadGameDetail event, Emitter<GameDetailState> emit) {
    print('[GameDetailBloc] Loading game: ${event.gameId}');
    emit(GameDetailLoading());

    gameRepository.getGameStream(event.gameId).listen(
      (game) {
        print('[GameDetailBloc] Received game from stream: ${game?.gameName}');
        if (game != null) {
          emit(GameDetailLoaded(game: game));
        } else {
          print('[GameDetailBloc] Game is null, emitting error');
          emit(GameDetailError(message: 'Game not found'));
        }
      },
      onError: (error) {
        print('[GameDetailBloc] Stream error: $error');
        emit(GameDetailError(message: error.toString()));
      },
    );
  }

  Future<void> _onStartGame(StartGame event, Emitter<GameDetailState> emit) async {
    try {
      await gameRepository.startGame(event.gameId);
    } catch (e) {
      emit(GameDetailError(message: e.toString()));
    }
  }

  Future<void> _onSubmitTaskAnswer(SubmitTaskAnswer event, Emitter<GameDetailState> emit) async {
    try {
      await gameRepository.submitTaskAnswer(
        event.gameId,
        event.taskId,
        event.submission,
      );
    } catch (e) {
      emit(GameDetailError(message: e.toString()));
    }
  }

  Future<void> _onJudgeSubmission(JudgeSubmission event, Emitter<GameDetailState> emit) async {
    try {
      await gameRepository.judgeSubmission(
        event.gameId,
        event.taskIndex,
        event.playerId,
        event.score,
      );
    } catch (e) {
      emit(GameDetailError(message: e.toString()));
    }
  }
}