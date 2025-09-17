import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/game.dart';
import '../../../../core/models/task.dart';
import '../../../../core/models/submission.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../games/presentation/bloc/game_detail_bloc.dart';
import '../widgets/submission_card.dart';

class JudgingScreen extends StatefulWidget {
  final String gameId;
  final Game game;

  const JudgingScreen({
    super.key,
    required this.gameId,
    required this.game,
  });

  @override
  State<JudgingScreen> createState() => _JudgingScreenState();
}

class _JudgingScreenState extends State<JudgingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTaskIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.game.tasks.length,
      vsync: this,
    );
    _tabController.addListener(() {
      setState(() {
        _currentTaskIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: Text('Authentication required')),
          );
        }

        final currentUser = authState.user;
        final isJudge = widget.game.isUserJudge(currentUser.id);

        if (!isJudge) {
          return Scaffold(
            appBar: AppBar(title: const Text('Access Denied')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Only the judge can access this screen'),
                ],
              ),
            ),
          );
        }

        if (widget.game.tasks.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Judge Panel')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No tasks available to judge'),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Judge Panel'),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: widget.game.tasks.map((task) {
                final pendingCount = task.submissions.where((s) => !s.isJudged).length;
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        task.title.length > 15 
                            ? '${task.title.substring(0, 15)}...'
                            : task.title,
                      ),
                      if (pendingCount > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$pendingCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: widget.game.tasks.map((task) {
              return _TaskJudgingView(
                task: task,
                gameId: widget.gameId,
                players: widget.game.players,
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _TaskJudgingView extends StatelessWidget {
  final Task task;
  final String gameId;
  final List players;

  const _TaskJudgingView({
    required this.task,
    required this.gameId,
    required this.players,
  });

  String _getPlayerName(String userId) {
    try {
      final player = players.firstWhere((p) => p.userId == userId);
      return player.displayName;
    } catch (e) {
      return 'Unknown Player';
    }
  }

  @override
  Widget build(BuildContext context) {
    final submissions = task.submissions;
    final pendingSubmissions = submissions.where((s) => !s.isJudged).toList();
    final judgedSubmissions = submissions.where((s) => s.isJudged).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Task Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        task.isVideoTask ? Icons.videocam : Icons.quiz,
                        color: task.isVideoTask ? Colors.red[700] : Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatusChip(
                        icon: Icons.pending,
                        label: 'Pending: ${pendingSubmissions.length}',
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(
                        icon: Icons.check_circle,
                        label: 'Judged: ${judgedSubmissions.length}',
                        color: Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Submissions List
          Expanded(
            child: submissions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No submissions yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Players haven\'t submitted for this task yet',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: submissions.length,
                    itemBuilder: (context, index) {
                      final submission = submissions[index];
                      final playerName = _getPlayerName(submission.userId);
                      
                      return SubmissionCard(
                        submission: submission,
                        playerName: playerName,
                        task: task,
                        gameId: gameId,
                        onScored: () {
                          // Refresh handled by BLoC
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}