part of 'games_bloc.dart';

abstract class GamesState extends Equatable {
  const GamesState();
  
  @override
  List<Object> get props => [];
}

class GamesInitial extends GamesState {}

class GamesLoading extends GamesState {}

class GamesLoaded extends GamesState {
  final List<Game> games;

  const GamesLoaded({required this.games});

  @override
  List<Object> get props => [games];
}

class GamesError extends GamesState {
  final String message;

  const GamesError({required this.message});

  @override
  List<Object> get props => [message];
}

class QuickPlaySuccess extends GamesState {
  final String gameId;

  const QuickPlaySuccess({required this.gameId});

  @override
  List<Object> get props => [gameId];
}