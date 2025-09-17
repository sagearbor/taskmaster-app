import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/models/game.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/repositories/game_repository.dart';
import '../bloc/game_detail_bloc.dart';
import '../widgets/game_lobby_view.dart';
import '../widgets/game_in_progress_view.dart';
import '../widgets/game_completed_view.dart';

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
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is GameDetailError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Something went wrong',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          if (state is GameDetailLoaded) {
            switch (state.game.status) {
              case GameStatus.lobby:
                return GameLobbyView(game: state.game);
              case GameStatus.inProgress:
                return GameInProgressView(game: state.game);
              case GameStatus.completed:
                return GameCompletedView(game: state.game);
            }
          }

          return const SizedBox.shrink();
        },
      ),
    );
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