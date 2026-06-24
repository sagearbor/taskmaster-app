import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/models/game.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/repositories/game_repository.dart';
import 'game_detail_screen.dart';

/// Public games gallery — discover games other people have shared and clone
/// their task list into a fresh game you own ("Play these tasks").
class DiscoverGamesScreen extends StatelessWidget {
  const DiscoverGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discover Games')),
      body: StreamBuilder<List<Game>>(
        stream: sl<GameRepository>().getPublicGamesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load public games'));
          }
          final games = snapshot.data ?? const [];
          if (games.isEmpty) {
            return _buildEmpty(context);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: games.length,
            itemBuilder: (context, i) => _PublicGameCard(game: games[i]),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.public_off, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text('No public games yet',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Make one of your games public to share it here',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _PublicGameCard extends StatelessWidget {
  final Game game;

  const _PublicGameCard({required this.game});

  Future<void> _clone(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Sign in to play these tasks')),
      );
      return;
    }
    try {
      final newId = await sl<GameRepository>().cloneGame(
        game,
        authState.user.id,
        authState.user.displayName,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Created your copy of "${game.gameName}"')),
      );
      navigator.push(
        MaterialPageRoute(builder: (_) => GameDetailScreen(gameId: newId)),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not clone game: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(game.gameName,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.assignment, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${game.tasks.length} task${game.tasks.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 12),
                Icon(Icons.group, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${game.players.length}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _clone(context),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play these tasks'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
