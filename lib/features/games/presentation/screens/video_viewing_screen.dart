import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/models/player_task_status.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/repositories/game_repository.dart';
import '../bloc/task_execution_bloc.dart';
import '../bloc/task_execution_event.dart';
import '../bloc/task_execution_state.dart';

class VideoViewingScreen extends StatelessWidget {
  final String gameId;
  final int taskIndex;

  const VideoViewingScreen({
    super.key,
    required this.gameId,
    required this.taskIndex,
  });

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthAuthenticated ? authState.user.uid : '';

    return BlocProvider(
      create: (context) => TaskExecutionBloc(
        gameRepository: sl<GameRepository>(),
      )..add(LoadTask(
          gameId: gameId,
          taskIndex: taskIndex,
          userId: userId,
        )),
      child: VideoViewingView(userId: userId),
    );
  }
}

class VideoViewingView extends StatelessWidget {
  final String userId;

  const VideoViewingView({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Submissions'),
      ),
      body: BlocBuilder<TaskExecutionBloc, TaskExecutionState>(
        builder: (context, state) {
          if (state is TaskExecutionLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is TaskExecutionError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          if (state is TaskExecutionLoaded) {
            // Privacy check: Only show if user has submitted
            if (!state.canUserViewVideos) {
              return _buildPrivacyBlock(context);
            }

            return _buildVideoGrid(context, state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPrivacyBlock(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock,
                size: 64,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Submit First to View Videos',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'To keep the game fair, you must submit your own video before you can view other players\' submissions.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back to Task'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoGrid(BuildContext context, TaskExecutionLoaded state) {
    final submissions = state.allPlayerStatuses.entries
        .where((entry) =>
            entry.value.hasSubmitted && entry.value.submissionUrl != null)
        .toList();

    if (submissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No submissions yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Waiting for other players to submit their videos.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task title
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.task.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.task.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Submissions (${submissions.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 12),

          // Video submissions grid
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              final entry = submissions[index];
              final playerId = entry.key;
              final status = entry.value;
              final isCurrentUser = playerId == userId;

              return _buildVideoCard(
                context,
                playerId,
                status,
                isCurrentUser,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(
    BuildContext context,
    String playerId,
    PlayerTaskStatus status,
    bool isCurrentUser,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isCurrentUser ? 4 : 1,
      child: InkWell(
        onTap: () => _openVideoUrl(context, status.submissionUrl!),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getAvatarColor(playerId),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        playerId[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isCurrentUser ? 'You' : _getShortPlayerId(playerId),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            if (isCurrentUser) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Your video',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color:
                                            Theme.of(context).colorScheme.secondary,
                                        fontSize: 10,
                                      ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatSubmissionTime(status.submittedAt!),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.play_circle_outline, size: 32),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.link,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        status.submissionUrl!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _openVideoUrl(context, status.submissionUrl!),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Open in Browser'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openVideoUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open video link'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getAvatarColor(String playerId) {
    final hash = playerId.hashCode;
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.deepOrange,
      Colors.cyan,
      Colors.lime,
    ];
    return colors[hash % colors.length];
  }

  String _getShortPlayerId(String playerId) {
    if (playerId.length > 8) {
      return playerId.substring(0, 8);
    }
    return playerId;
  }

  String _formatSubmissionTime(DateTime submittedAt) {
    final now = DateTime.now();
    final difference = now.difference(submittedAt);

    if (difference.inMinutes < 1) {
      return 'Submitted just now';
    }
    if (difference.inMinutes < 60) {
      return 'Submitted ${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return 'Submitted ${difference.inHours}h ago';
    }
    return 'Submitted ${difference.inDays}d ago';
  }
}