import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/game.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/game_detail_bloc.dart';

class GameLobbyView extends StatelessWidget {
  final Game game;

  const GameLobbyView({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Center(child: Text('Authentication required'));
        }

        final currentUser = authState.user;
        final isCreator = game.isUserCreator(currentUser.id);
        final isJudge = game.isUserJudge(currentUser.id);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Game Status Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.people,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Waiting for players',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${game.players.length} player${game.players.length == 1 ? '' : 's'} joined',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Invite Code: ',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              game.inviteCode,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Players List
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Players (${game.players.length})',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (game.players.isEmpty)
                          Expanded(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.group_add,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No players yet',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Share the invite code to get started!',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: ListView.builder(
                              itemCount: game.players.length,
                              itemBuilder: (context, index) {
                                final player = game.players[index];
                                final isCurrentUser = player.userId == currentUser.id;
                                final isPlayerJudge = game.judgeId == player.userId;
                                final isPlayerCreator = game.creatorId == player.userId;

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isCurrentUser 
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey[300],
                                    child: Text(
                                      player.displayName.isNotEmpty 
                                          ? player.displayName[0].toUpperCase()
                                          : 'P',
                                      style: TextStyle(
                                        color: isCurrentUser ? Colors.white : Colors.grey[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    player.displayName,
                                    style: TextStyle(
                                      fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      if (isPlayerCreator) ...[
                                        Icon(Icons.star, size: 16, color: Colors.amber[700]),
                                        const SizedBox(width: 4),
                                        Text('Creator', style: TextStyle(color: Colors.amber[700])),
                                      ],
                                      if (isPlayerJudge) ...[
                                        if (isPlayerCreator) const SizedBox(width: 8),
                                        Icon(Icons.gavel, size: 16, color: Colors.purple[700]),
                                        const SizedBox(width: 4),
                                        Text('Judge', style: TextStyle(color: Colors.purple[700])),
                                      ],
                                      if (isCurrentUser && !isPlayerCreator && !isPlayerJudge) ...[
                                        Icon(Icons.person, size: 16, color: Colors.blue[700]),
                                        const SizedBox(width: 4),
                                        Text('You', style: TextStyle(color: Colors.blue[700])),
                                      ],
                                    ],
                                  ),
                                  trailing: isCurrentUser 
                                      ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                                      : null,
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              if (isCreator) ...[
                ElevatedButton.icon(
                  onPressed: game.players.length >= 2 && game.tasks.isNotEmpty
                      ? () {
                          context.read<GameDetailBloc>().add(StartGame(gameId: game.id));
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    'Start Game',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  game.players.length < 2
                      ? 'Need at least 2 players to start'
                      : game.tasks.isEmpty
                          ? 'Need to add tasks before starting'
                          : 'Ready to start! (${game.tasks.length} task${game.tasks.length == 1 ? '' : 's'}, ${game.players.length} player${game.players.length == 1 ? '' : 's'})',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: game.players.length >= 2 && game.tasks.isNotEmpty
                        ? Colors.green[700]
                        : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Waiting for the game creator to start the game...',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}