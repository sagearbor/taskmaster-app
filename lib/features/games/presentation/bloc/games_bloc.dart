import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/models/game.dart';
import '../../domain/repositories/game_repository.dart';

part 'games_event.dart';
part 'games_state.dart';

class GamesBloc extends Bloc<GamesEvent, GamesState> {
  final GameRepository gameRepository;

  GamesBloc({required this.gameRepository}) : super(GamesInitial()) {
    on<LoadGames>(_onLoadGames);
    on<CreateGame>(_onCreateGame);
    on<JoinGame>(_onJoinGame);
    on<DeleteGame>(_onDeleteGame);
  }

  void _onLoadGames(LoadGames event, Emitter<GamesState> emit) {
    emit(GamesLoading());
    
    gameRepository.getGamesStream().listen(
      (games) {
        emit(GamesLoaded(games: games));
      },
      onError: (error) {
        emit(GamesError(message: error.toString()));
      },
    );
  }

  Future<void> _onCreateGame(CreateGame event, Emitter<GamesState> emit) async {
    emit(GamesLoading());
    try {
      await gameRepository.createGame(
        event.gameName,
        event.creatorId,
        event.judgeId,
      );
      add(LoadGames());
    } catch (e) {
      emit(GamesError(message: e.toString()));
    }
  }

  Future<void> _onJoinGame(JoinGame event, Emitter<GamesState> emit) async {
    try {
      await gameRepository.joinGame(
        event.inviteCode,
        event.userId,
        event.displayName,
      );
      add(LoadGames());
    } catch (e) {
      emit(GamesError(message: e.toString()));
    }
  }

  Future<void> _onDeleteGame(DeleteGame event, Emitter<GamesState> emit) async {
    try {
      await gameRepository.deleteGame(event.gameId);
      add(LoadGames());
    } catch (e) {
      emit(GamesError(message: e.toString()));
    }
  }
}