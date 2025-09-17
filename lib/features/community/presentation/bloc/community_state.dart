part of 'community_bloc.dart';

abstract class CommunityState extends Equatable {
  const CommunityState();
  
  @override
  List<Object> get props => [];
}

class CommunityInitial extends CommunityState {}

class CommunityLoading extends CommunityState {}

class CommunityLoaded extends CommunityState {
  final List<CommunityTask> tasks;

  const CommunityLoaded({required this.tasks});

  @override
  List<Object> get props => [tasks];
}

class CommunityError extends CommunityState {
  final String message;

  const CommunityError({required this.message});

  @override
  List<Object> get props => [message];
}