part of 'game_detail_bloc.dart';

abstract class GameDetailState extends Equatable {
  const GameDetailState();
  
  @override
  List<Object> get props => [];
}

class GameDetailInitial extends GameDetailState {}

class GameDetailLoading extends GameDetailState {}

class GameDetailLoaded extends GameDetailState {
  final Game game;

  const GameDetailLoaded({required this.game});

  @override
  List<Object> get props => [game];
}

class GameDetailError extends GameDetailState {
  final String message;

  const GameDetailError({required this.message});

  @override
  List<Object> get props => [message];
}