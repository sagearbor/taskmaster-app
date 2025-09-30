import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/game_repository.dart';
import '../../../../core/models/player_task_status.dart';
import 'task_execution_event.dart';
import 'task_execution_state.dart';

class TaskExecutionBloc extends Bloc<TaskExecutionEvent, TaskExecutionState> {
  final GameRepository gameRepository;

  TaskExecutionBloc({required this.gameRepository})
      : super(TaskExecutionInitial()) {
    on<LoadTask>(_onLoadTask);
    on<StartTask>(_onStartTask);
    on<SubmitTask>(_onSubmitTask);
    on<SkipTask>(_onSkipTask);
  }

  Future<void> _onLoadTask(
    LoadTask event,
    Emitter<TaskExecutionState> emit,
  ) async {
    try {
      emit(TaskExecutionLoading());

      // Listen to game stream to get real-time updates
      await emit.forEach(
        gameRepository.getGameStream(event.gameId),
        onData: (game) {
          if (game == null) {
            return TaskExecutionError(message: 'Game not found');
          }

          if (event.taskIndex >= game.tasks.length) {
            return TaskExecutionError(message: 'Task not found');
          }

          final task = game.tasks[event.taskIndex];
          final userStatus = task.getPlayerStatus(event.userId);
          final allPlayerStatuses = task.playerStatuses;

          return TaskExecutionLoaded(
            task: task,
            userStatus: userStatus,
            allPlayerStatuses: allPlayerStatuses,
            taskNumber: event.taskIndex + 1,
            totalTasks: game.tasks.length,
          );
        },
        onError: (error, stackTrace) {
          return TaskExecutionError(message: error.toString());
        },
      );
    } catch (e) {
      emit(TaskExecutionError(message: e.toString()));
    }
  }

  Future<void> _onStartTask(
    StartTask event,
    Emitter<TaskExecutionState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! TaskExecutionLoaded) return;

      // Get current game
      final game = await gameRepository
          .getGameStream(event.gameId)
          .first;

      if (game == null) {
        emit(const TaskExecutionError(message: 'Game not found'));
        return;
      }

      final task = game.tasks[event.taskIndex];
      final currentStatus = task.getPlayerStatus(event.userId);

      if (currentStatus == null) {
        emit(const TaskExecutionError(message: 'Player status not found'));
        return;
      }

      // Update player status to in_progress
      final updatedStatus = currentStatus.copyWith(
        state: TaskPlayerState.in_progress,
        startedAt: DateTime.now(),
      );

      final updatedTask = task.copyWith(
        playerStatuses: {
          ...task.playerStatuses,
          event.userId: updatedStatus,
        },
      );

      final updatedTasks = List<Task>.from(game.tasks);
      updatedTasks[event.taskIndex] = updatedTask;

      final updatedGame = game.copyWith(tasks: updatedTasks);

      await gameRepository.updateGame(event.gameId, updatedGame);
    } catch (e) {
      emit(TaskExecutionError(message: e.toString()));
    }
  }

  Future<void> _onSubmitTask(
    SubmitTask event,
    Emitter<TaskExecutionState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! TaskExecutionLoaded) return;

      // Get current game
      final game = await gameRepository
          .getGameStream(event.gameId)
          .first;

      if (game == null) {
        emit(const TaskExecutionError(message: 'Game not found'));
        return;
      }

      final task = game.tasks[event.taskIndex];
      final currentStatus = task.getPlayerStatus(event.userId);

      if (currentStatus == null) {
        emit(const TaskExecutionError(message: 'Player status not found'));
        return;
      }

      // Update player status to submitted
      final updatedStatus = currentStatus.copyWith(
        state: TaskPlayerState.submitted,
        submittedAt: DateTime.now(),
        submissionUrl: event.videoUrl,
      );

      final updatedPlayerStatuses = {
        ...task.playerStatuses,
        event.userId: updatedStatus,
      };

      // Check if all players submitted
      final allSubmitted =
          updatedPlayerStatuses.values.every((s) => s.hasSubmitted);

      final updatedTask = task.copyWith(
        playerStatuses: updatedPlayerStatuses,
        status: allSubmitted
            ? TaskStatus.ready_to_judge
            : TaskStatus.waiting_for_submissions,
      );

      final updatedTasks = List<Task>.from(game.tasks);
      updatedTasks[event.taskIndex] = updatedTask;

      final updatedGame = game.copyWith(tasks: updatedTasks);

      await gameRepository.updateGame(event.gameId, updatedGame);

      emit(TaskExecutionSubmitted(
        gameId: event.gameId,
        taskIndex: event.taskIndex,
      ));
    } catch (e) {
      emit(TaskExecutionError(message: e.toString()));
    }
  }

  Future<void> _onSkipTask(
    SkipTask event,
    Emitter<TaskExecutionState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! TaskExecutionLoaded) return;

      // Get current game
      final game = await gameRepository
          .getGameStream(event.gameId)
          .first;

      if (game == null) {
        emit(const TaskExecutionError(message: 'Game not found'));
        return;
      }

      // Check if game settings allow skips
      if (!game.settings.allowSkips) {
        emit(const TaskExecutionError(
            message: 'Skipping tasks is not allowed in this game'));
        return;
      }

      final task = game.tasks[event.taskIndex];
      final currentStatus = task.getPlayerStatus(event.userId);

      if (currentStatus == null) {
        emit(const TaskExecutionError(message: 'Player status not found'));
        return;
      }

      // Update player status to skipped
      final updatedStatus = currentStatus.copyWith(
        state: TaskPlayerState.skipped,
      );

      final updatedPlayerStatuses = {
        ...task.playerStatuses,
        event.userId: updatedStatus,
      };

      // Check if all players submitted or skipped
      final allDone = updatedPlayerStatuses.values
          .every((s) => s.hasSubmitted || s.state == TaskPlayerState.skipped);

      final updatedTask = task.copyWith(
        playerStatuses: updatedPlayerStatuses,
        status:
            allDone ? TaskStatus.ready_to_judge : TaskStatus.waiting_for_submissions,
      );

      final updatedTasks = List<Task>.from(game.tasks);
      updatedTasks[event.taskIndex] = updatedTask;

      final updatedGame = game.copyWith(tasks: updatedTasks);

      await gameRepository.updateGame(event.gameId, updatedGame);

      emit(TaskExecutionSubmitted(
        gameId: event.gameId,
        taskIndex: event.taskIndex,
      ));
    } catch (e) {
      emit(TaskExecutionError(message: e.toString()));
    }
  }
}