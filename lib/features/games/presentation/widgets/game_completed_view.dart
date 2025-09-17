import 'package:flutter/material.dart';

import '../../../../core/models/game.dart';

class GameCompletedView extends StatelessWidget {
  final Game game;

  const GameCompletedView({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    // Sort players by total score
    final sortedPlayers = List.from(game.players)
      ..sort((a, b) => b.totalScore.compareTo(a.totalScore));

    final winner = sortedPlayers.isNotEmpty ? sortedPlayers.first : null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Winner Announcement
          if (winner != null)
            Card(
              color: Colors.amber.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 64,
                      color: Colors.amber[700],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '🎉 Winner! 🎉',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      winner.displayName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${winner.totalScore} points',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.amber[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Final Scoreboard
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Final Scoreboard',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: sortedPlayers.length,
                        itemBuilder: (context, index) {
                          final player = sortedPlayers[index];
                          final rank = index + 1;
                          
                          Color? rankColor;
                          IconData? rankIcon;
                          
                          if (rank == 1) {
                            rankColor = Colors.amber[700];
                            rankIcon = Icons.emoji_events;
                          } else if (rank == 2) {
                            rankColor = Colors.grey[600];
                            rankIcon = Icons.military_tech;
                          } else if (rank == 3) {
                            rankColor = Colors.brown[400];
                            rankIcon = Icons.military_tech;
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: rank <= 3 ? rankColor?.withOpacity(0.1) : null,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: rankColor ?? Colors.grey[400],
                                child: rankIcon != null
                                    ? Icon(rankIcon, color: Colors.white, size: 20)
                                    : Text(
                                        '$rank',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                              title: Text(
                                player.displayName,
                                style: TextStyle(
                                  fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text('Rank #$rank'),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${player.totalScore} pts',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
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

          // Game Statistics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Game Statistics',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        icon: Icons.people,
                        label: 'Players',
                        value: '${game.players.length}',
                      ),
                      _StatItem(
                        icon: Icons.assignment,
                        label: 'Tasks',
                        value: '${game.tasks.length}',
                      ),
                      _StatItem(
                        icon: Icons.video_library,
                        label: 'Submissions',
                        value: '${game.tasks.fold<int>(0, (sum, task) => sum + task.submissions.length)}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement share results functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Share feature coming soon!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share Results'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}