import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/models/community_task.dart';
import '../../../tasks/domain/repositories/task_repository.dart';

part 'community_event.dart';
part 'community_state.dart';

class CommunityBloc extends Bloc<CommunityEvent, CommunityState> {
  final TaskRepository taskRepository;

  CommunityBloc({required this.taskRepository}) : super(CommunityInitial()) {
    on<LoadCommunityTasks>(_onLoadCommunityTasks);
    on<SubmitCommunityTask>(_onSubmitCommunityTask);
    on<UpvoteTask>(_onUpvoteTask);
    on<SearchCommunityTasks>(_onSearchCommunityTasks);
    on<FilterTasksByType>(_onFilterTasksByType);
  }

  Future<void> _onLoadCommunityTasks(LoadCommunityTasks event, Emitter<CommunityState> emit) async {
    emit(CommunityLoading());
    try {
      final tasks = await taskRepository.getCommunityTasks();
      emit(CommunityLoaded(tasks: tasks));
    } catch (e) {
      emit(CommunityError(message: e.toString()));
    }
  }

  Future<void> _onSubmitCommunityTask(SubmitCommunityTask event, Emitter<CommunityState> emit) async {
    try {
      await taskRepository.createCommunityTask(event.task);
      add(LoadCommunityTasks());
    } catch (e) {
      emit(CommunityError(message: e.toString()));
    }
  }

  Future<void> _onUpvoteTask(UpvoteTask event, Emitter<CommunityState> emit) async {
    try {
      await taskRepository.upvoteTask(event.taskId);
      add(LoadCommunityTasks());
    } catch (e) {
      emit(CommunityError(message: e.toString()));
    }
  }

  Future<void> _onSearchCommunityTasks(SearchCommunityTasks event, Emitter<CommunityState> emit) async {
    emit(CommunityLoading());
    try {
      // For now, filter loaded tasks locally
      // In production, this would be a server-side search
      final allTasks = await taskRepository.getCommunityTasks();
      final filteredTasks = allTasks.where((task) =>
        task.title.toLowerCase().contains(event.query.toLowerCase()) ||
        task.description.toLowerCase().contains(event.query.toLowerCase())
      ).toList();
      
      emit(CommunityLoaded(tasks: filteredTasks));
    } catch (e) {
      emit(CommunityError(message: e.toString()));
    }
  }

  Future<void> _onFilterTasksByType(FilterTasksByType event, Emitter<CommunityState> emit) async {
    emit(CommunityLoading());
    try {
      final allTasks = await taskRepository.getCommunityTasks();
      final filteredTasks = event.taskType == null 
          ? allTasks
          : allTasks.where((task) => task.taskType == event.taskType).toList();
      
      emit(CommunityLoaded(tasks: filteredTasks));
    } catch (e) {
      emit(CommunityError(message: e.toString()));
    }
  }
}