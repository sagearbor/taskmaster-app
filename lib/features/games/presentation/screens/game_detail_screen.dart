import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/models/game.dart';
import '../../../../core/models/task.dart';
import '../../../../core/models/player_task_status.dart';
import '../../../../core/widgets/skeleton_loaders.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/repositories/game_repository.dart';
import '../bloc/game_detail_bloc.dart';
import '../widgets/game_lobby_view.dart';
import '../widgets/game_in_progress_view.dart';
import '../widgets/game_completed_view.dart';
import '../widgets/game_status_banner.dart';

class GameDetailScreen extends StatelessWidget {
  final String gameId;

  const GameDetailScreen({
    super.key,
    required this.gameId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GameDetailBloc(
        gameRepository: sl<GameRepository>(),
      )..add(LoadGameDetail(gameId: gameId)),
      child: const GameDetailView(),
    );
  }
}

class GameDetailView extends StatelessWidget {
  const GameDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<GameDetailBloc, GameDetailState>(
          builder: (context, state) {
            if (state is GameDetailLoaded) {
              return Text(state.game.gameName);
            }
            return const Text('Game Details');
          },
        ),
        actions: [
          BlocBuilder<GameDetailBloc, GameDetailState>(
            builder: (context, state) {
              if (state is GameDetailLoaded) {
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'share') {
                      _showShareDialog(context, state.game);
                    }
                  },
                  itemBuilder: (context) => [
                    if (state.game.isInLobby)
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share),
                            SizedBox(width: 8),
                            Text('Share Invite'),
                          ],
                        ),
                      ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<GameDetailBloc, GameDetailState>(
        listener: (context, state) {
          if (state is GameDetailError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is GameDetailLoading) {
            return SkeletonLoaders.gameDetailSkeleton(context);
          }

          if (state is GameDetailError) {
            return ErrorView(
              message: 'Failed to load game',
              details: state.message,
              onRetry: () {
                final gameId = context.read<GameDetailBloc>().gameId;
                if (gameId != null) {
                  context.read<GameDetailBloc>().add(LoadGameDetail(gameId: gameId));
                }
              },
            );
          }

          if (state is GameDetailLoaded) {
            final authState = context.read<AuthBloc>().state;
            final currentUserId = authState is AuthAuthenticated ? authState.user.id : '';
            final isJudge = state.game.judgeId == currentUserId;

            return Column(
              children: [
                // Add status banner at the top
                GameStatusBanner(
                  game: state.game,
                  currentUserId: currentUserId,
                  isJudge: isJudge,
                  onAction: () {
                    // Handle banner action based on game state
                    _handleBannerAction(context, state.game, currentUserId);
                  },
                ),
                Expanded(
                  child: switch (state.game.status) {
                    GameStatus.lobby => GameLobbyView(game: state.game),
                    GameStatus.inProgress => GameInProgressView(game: state.game),
                    GameStatus.completed => GameCompletedView(game: state.game),
                  },
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _handleBannerAction(BuildContext context, Game game, String currentUserId) {
    // Handle different banner actions based on game state
    if (game.status == GameStatus.lobby && game.creatorId == currentUserId && game.players.length >= 2) {
      // Start game action
      context.read<GameDetailBloc>().add(StartGame(gameId: game.id!));
    } else if (game.status == GameStatus.inProgress && game.tasks.isNotEmpty) {
      final currentTask = game.tasks[game.currentTaskIndex];
      final playerStatus = currentTask.playerStatuses[currentUserId];

      if (playerStatus?.state == TaskPlayerState.not_started ||
          playerStatus?.state == TaskPlayerState.in_progress) {
        // Navigate to task execution
        Navigator.pushNamed(
          context,
          '/task-execution',
          arguments: {
            'gameId': game.id!,
            'taskIndex': game.currentTaskIndex,
            'userId': currentUserId,
          },
        );
      } else if (game.judgeId == currentUserId && currentTask.status == TaskStatus.ready_to_judge) {
        // Navigate to judging
        Navigator.pushNamed(
          context,
          '/judging',
          arguments: {
            'gameId': game.id!,
            'taskIndex': game.currentTaskIndex,
          },
        );
      } else if (currentTask.status == TaskStatus.completed) {
        // Navigate to scoreboard
        context.read<GameDetailBloc>().add(
          ViewTaskResultsEvent(
            gameId: game.id!,
            taskIndex: game.currentTaskIndex,
          ),
        );
      }
    } else if (game.status == GameStatus.lobby && game.players.length < 2) {
      // Share invite code
      _showShareDialog(context, game);
    }
  }

  void _showShareDialog(BuildContext context, Game game) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Game Invite'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share this invite code with your friends:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    game.inviteCode,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Game: ${game.gameName}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}