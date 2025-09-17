part of 'community_bloc.dart';

abstract class CommunityEvent extends Equatable {
  const CommunityEvent();

  @override
  List<Object?> get props => [];
}

class LoadCommunityTasks extends CommunityEvent {}

class SubmitCommunityTask extends CommunityEvent {
  final CommunityTask task;

  const SubmitCommunityTask({required this.task});

  @override
  List<Object> get props => [task];
}

class UpvoteTask extends CommunityEvent {
  final String taskId;

  const UpvoteTask({required this.taskId});

  @override
  List<Object> get props => [taskId];
}

class SearchCommunityTasks extends CommunityEvent {
  final String query;

  const SearchCommunityTasks({required this.query});

  @override
  List<Object> get props => [query];
}

class FilterTasksByType extends CommunityEvent {
  final TaskType? taskType;

  const FilterTasksByType({this.taskType});

  @override
  List<Object?> get props => [taskType];
}