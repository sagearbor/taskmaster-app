import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/skeleton_loaders.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../games/domain/repositories/game_repository.dart';
import '../../../games/presentation/bloc/games_bloc.dart';
import '../../../games/presentation/screens/create_game_screen.dart';
import '../../../games/presentation/screens/join_game_screen.dart';
import '../../../games/presentation/screens/game_detail_screen.dart';
import '../widgets/game_card.dart';
import '../widgets/home_app_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GamesBloc(
        gameRepository: sl<GameRepository>(),
      )..add(LoadGames()),
      child: const HomeView(),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HomeAppBar(),
      body: BlocBuilder<GamesBloc, GamesState>(
        builder: (context, state) {
          if (state is GamesLoading) {
            return SkeletonLoaders.listSkeleton(
              itemCount: 3,
              itemHeight: 120,
            );
          }

          if (state is GamesError) {
            return ErrorView(
              message: 'Failed to load games',
              details: state.message,
              onRetry: () {
                context.read<GamesBloc>().add(LoadGames());
              },
            );
          }

          if (state is GamesLoaded) {
            if (state.games.isEmpty) {
              return ErrorView.empty(
                entity: 'games',
                action: 'create your first game',
                onAction: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<AuthBloc>(),
                        child: const CreateGameScreen(),
                      ),
                    ),
                  );
                },
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<GamesBloc>().add(LoadGames());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.games.length,
                itemBuilder: (context, index) {
                  final game = state.games[index];
                  return GameCard(
                    game: game,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => GameDetailScreen(gameId: game.id),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'join',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const JoinGameScreen(),
                ),
              );
            },
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: const Icon(Icons.group_add),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'create',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<AuthBloc>(),
                    child: const CreateGameScreen(),
                  ),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}