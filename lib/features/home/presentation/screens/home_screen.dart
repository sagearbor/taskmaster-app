import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/skeleton_loaders.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
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
        authRepository: sl<AuthRepository>(),
      )..add(LoadGames()),
      child: const HomeView(),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<GamesBloc, GamesState>(
      listener: (context, state) {
        if (state is QuickPlaySuccess) {
          // Navigate directly to game detail
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => GameDetailScreen(gameId: state.gameId),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: const HomeAppBar(),
        body: Column(
          children: [
            // Quick Play Hero Banner
            _buildQuickPlayBanner(context),
            // Games List
            Expanded(
              child: BlocBuilder<GamesBloc, GamesState>(
                builder: (context, state) {
                  return _buildGamesContent(context, state);
                },
              ),
            ),
          ],
        ),
        floatingActionButton: _buildFloatingButtons(context),
      ),
    );
  }

  Widget _buildQuickPlayBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        child: InkWell(
          onTap: () {
            context.read<GamesBloc>().add(const QuickPlayGame());
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.flash_on,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⚡ Quick Play',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Jump into a game in seconds!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGamesContent(BuildContext context, GamesState state) {
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
  }

  Widget _buildFloatingButtons(BuildContext context) {
    return Column(
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
    );
  }
}