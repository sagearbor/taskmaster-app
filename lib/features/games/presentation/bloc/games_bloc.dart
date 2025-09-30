import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/models/game.dart';
import '../../../../core/models/player.dart';
import '../../../../core/models/game_settings.dart';
import '../../../../core/models/task.dart';
import '../../../../core/models/player_task_status.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../tasks/data/datasources/prebuilt_tasks_data.dart';
import '../../domain/repositories/game_repository.dart';

part 'games_event.dart';
part 'games_state.dart';

class GamesBloc extends Bloc<GamesEvent, GamesState> {
  final GameRepository gameRepository;
  final AuthRepository authRepository;

  GamesBloc({
    required this.gameRepository,
    required this.authRepository,
  }) : super(GamesInitial()) {
    on<LoadGames>(_onLoadGames);
    on<CreateGame>(_onCreateGame);
    on<JoinGame>(_onJoinGame);
    on<DeleteGame>(_onDeleteGame);
    on<QuickPlayGame>(_onQuickPlayGame);
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

  Future<void> _onQuickPlayGame(
    QuickPlayGame event,
    Emitter<GamesState> emit,
  ) async {
    emit(GamesLoading());

    try {
      // Get current user
      final user = await authRepository.getCurrentUser();
      if (user == null) {
        throw Exception('Not authenticated');
      }

      // Generate fun game name
      final gameName = _generateGameName();

      // Select 5 random tasks from different categories
      final randomTasks = _getRandomTasks(count: 5);

      // Initialize player statuses for all tasks
      final initializedTasks = randomTasks.map((task) {
        return task.copyWith(
          playerStatuses: {
            user.id: PlayerTaskStatus(
              playerId: user.id,
              state: TaskPlayerState.not_started,
            ),
          },
          status: TaskStatus.waiting_for_submissions,
        );
      }).toList();

      // Set deadline for first task
      final firstTaskDeadline = DateTime.now().add(const Duration(hours: 24));
      if (initializedTasks.isNotEmpty) {
        initializedTasks[0] = initializedTasks[0].copyWith(deadline: firstTaskDeadline);
      }

      // Create game object
      final game = Game(
        id: '', // Firestore will generate
        gameName: gameName,
        creatorId: user.id,
        judgeId: user.id, // Creator is judge in Quick Play
        status: GameStatus.inProgress, // Skip lobby!
        inviteCode: _generateInviteCode(),
        players: [
          Player(
            userId: user.id,
            displayName: user.displayName,
            totalScore: 0,
          ),
        ],
        tasks: initializedTasks,
        currentTaskIndex: 0,
        createdAt: DateTime.now(),
        mode: GameMode.async,
        settings: GameSettings.quickPlay(),
      );

      // Create in Firestore via updateGame (since createGame doesn't support full Game objects)
      // First create basic game
      final gameId = await gameRepository.createGame(
        gameName,
        user.id,
        user.id,
      );

      // Then update with full game data including tasks
      final completeGame = game.copyWith(id: gameId);
      await gameRepository.updateGame(gameId, completeGame);

      emit(QuickPlaySuccess(gameId: gameId));
    } catch (e) {
      emit(GamesError(message: e.toString()));
    }
  }

  String _generateGameName() {
    final adjectives = ['Epic', 'Awesome', 'Crazy', 'Wild', 'Fun', 'Amazing', 'Super', 'Mega'];
    final nouns = ['Adventure', 'Challenge', 'Quest', 'Game', 'Mission', 'Journey', 'Party'];
    final random = Random();
    final adj = adjectives[random.nextInt(adjectives.length)];
    final noun = nouns[random.nextInt(nouns.length)];
    return '$adj $noun #${random.nextInt(9999).toString().padLeft(4, '0')}';
  }

  String _generateInviteCode() {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  List<Task> _getRandomTasks({required int count}) {
    final allTasks = PrebuiltTasksData.getAllTasks();
    final random = Random();

    // Shuffle and take first 'count' tasks
    final shuffled = List<Task>.from(allTasks)..shuffle(random);
    return shuffled.take(count).toList();
  }
}