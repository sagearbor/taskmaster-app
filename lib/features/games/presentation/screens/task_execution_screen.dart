import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/models/player_task_status.dart';
import '../../../../core/widgets/skeleton_loaders.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/repositories/game_repository.dart';
import '../bloc/task_execution_bloc.dart';
import '../bloc/task_execution_event.dart';
import '../bloc/task_execution_state.dart';
import '../widgets/submission_progress_widget.dart';
import '../widgets/task_timer_widget.dart';
import 'video_viewing_screen.dart';

class TaskExecutionScreen extends StatelessWidget {
  final String gameId;
  final int taskIndex;

  const TaskExecutionScreen({
    super.key,
    required this.gameId,
    required this.taskIndex,
  });

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthAuthenticated ? authState.user.id : '';

    return BlocProvider(
      create: (context) => TaskExecutionBloc(
        gameRepository: sl<GameRepository>(),
      )..add(LoadTask(
          gameId: gameId,
          taskIndex: taskIndex,
          userId: userId,
        )),
      child: TaskExecutionView(
        gameId: gameId,
        taskIndex: taskIndex,
        userId: userId,
      ),
    );
  }
}

class TaskExecutionView extends StatefulWidget {
  final String gameId;
  final int taskIndex;
  final String userId;

  const TaskExecutionView({
    super.key,
    required this.gameId,
    required this.taskIndex,
    required this.userId,
  });

  @override
  State<TaskExecutionView> createState() => _TaskExecutionViewState();
}

class _TaskExecutionViewState extends State<TaskExecutionView> {
  final _videoUrlController = TextEditingController();
  bool _isUrlValid = false;

  @override
  void dispose() {
    _videoUrlController.dispose();
    super.dispose();
  }

  void _validateUrl(String url) {
    setState(() {
      _isUrlValid = _isValidVideoUrl(url);
    });
  }

  bool _isValidVideoUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;

    // Accept any well-formed http(s) URL with a real host. We deliberately do
    // not gate on a hardcoded allowlist of platforms: players legitimately host
    // videos in many places, and blocking valid links was a dead end. The
    // platform names in the UI are guidance only.
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return false;
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;
    return uri.host.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Check if user has entered text but not submitted
        if (_videoUrlController.text.isNotEmpty) {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Discard submission?'),
              content: const Text(
                'You have entered a video URL. Are you sure you want to leave without submitting?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Stay'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Leave'),
                ),
              ],
            ),
          );
          return shouldPop ?? false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
        title: BlocBuilder<TaskExecutionBloc, TaskExecutionState>(
          builder: (context, state) {
            if (state is TaskExecutionLoaded) {
              return Text('Task ${state.taskNumber} of ${state.totalTasks}');
            }
            return const Text('Task Execution');
          },
        ),
      ),
      body: BlocConsumer<TaskExecutionBloc, TaskExecutionState>(
        listener: (context, state) {
          if (state is TaskExecutionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }

          if (state is TaskExecutionSubmitted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Submission successful! ✅')),
            );
            // Return to the game. (The old code pushed a named route
            // '/video-viewing' that was never registered, which left the
            // screen stuck blank after a successful submit.)
            Future.delayed(const Duration(milliseconds: 600), () {
              if (context.mounted) Navigator.of(context).pop();
            });
          }
        },
        builder: (context, state) {
          if (state is TaskExecutionLoading) {
            return SkeletonLoaders.taskExecutionSkeleton(context);
          }

          if (state is TaskExecutionError) {
            return ErrorView(
              message: 'Failed to load task',
              details: state.message,
              onRetry: () {
                context.read<TaskExecutionBloc>().add(LoadTask(
                  gameId: widget.gameId,
                  taskIndex: widget.taskIndex,
                  userId: widget.userId,
                ));
              },
            );
          }

          if (state is TaskExecutionLoaded) {
            // Check if user already submitted
            if (state.hasUserSubmitted) {
              return _buildAlreadySubmittedView(context, state);
            }

            return _buildTaskExecutionForm(context, state);
          }

          // Initial / Submitted — show a spinner instead of a blank screen.
          return const Center(child: CircularProgressIndicator());
        },
      ),
    ),
    );
  }

  Widget _buildAlreadySubmittedView(
      BuildContext context, TaskExecutionLoaded state) {
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
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 64,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Already Submitted ✅',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'You have already submitted this task!',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (state.userStatus?.submissionUrl != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.videocam, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Your submission',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.userStatus!.submissionUrl!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (state.userStatus!.submittedAt != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Submitted ${_formatTimeAgo(state.userStatus!.submittedAt!)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (state.task.deadline != null &&
                          state.userStatus!.submittedAt != null &&
                          state.userStatus!.submittedAt!.isBefore(state.task.deadline!)) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.timer, size: 16, color: Colors.green[600]),
                            const SizedBox(width: 4),
                            Text(
                              'Submitted on time',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.green[600],
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            SubmissionProgressWidget(
              playerStatuses: state.allPlayerStatuses,
              currentUserId: widget.userId,
            ),
            const SizedBox(height: 32),
            if (state.canUserViewVideos)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => VideoViewingScreen(
                      gameId: widget.gameId,
                      taskIndex: widget.taskIndex,
                    ),
                  ));
                },
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('View Submissions'),
              ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to Game'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskExecutionForm(
      BuildContext context, TaskExecutionLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Task Title
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.task.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.task.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Timer Widget (if task has duration)
          if (state.task.durationSeconds != null)
            TaskTimerWidget(
              durationSeconds: state.task.durationSeconds!,
              onTimeExpired: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Time is up! Please submit your video.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),

          const SizedBox(height: 16),

          // Deadline (if task has deadline)
          if (state.task.deadline != null)
            Card(
              color: state.task.hasDeadlinePassed
                  ? Colors.red.withOpacity(0.1)
                  : Colors.blue.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(
                      state.task.hasDeadlinePassed
                          ? Icons.warning
                          : Icons.schedule,
                      color: state.task.hasDeadlinePassed
                          ? Colors.red
                          : Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.task.hasDeadlinePassed
                                ? 'Deadline Passed'
                                : 'Submit by:',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            _formatDeadline(state.task.deadline!),
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
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

          // Submission Progress
          SubmissionProgressWidget(
            playerStatuses: state.allPlayerStatuses,
            currentUserId: widget.userId,
          ),

          const SizedBox(height: 24),

          // Video URL Input
          Text(
            'Submit Your Video',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Paste a link to your video (YouTube, Google Photos, etc.)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _videoUrlController,
            decoration: InputDecoration(
              labelText: 'Video URL',
              hintText: 'https://youtube.com/watch?v=...',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.link),
              suffixIcon: _isUrlValid
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
            ),
            keyboardType: TextInputType.url,
            onChanged: _validateUrl,
          ),

          const SizedBox(height: 24),

          // Submit Button
          ElevatedButton(
            onPressed: _isUrlValid
                ? () {
                    context.read<TaskExecutionBloc>().add(
                          SubmitTask(
                            gameId: widget.gameId,
                            taskIndex: widget.taskIndex,
                            userId: widget.userId,
                            videoUrl: _videoUrlController.text.trim(),
                          ),
                        );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Submit Video',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          // Skip Button (if allowed)
          if (state.task.playerStatuses[widget.userId]?.state !=
              TaskPlayerState.skipped) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                _showSkipConfirmation(context);
              },
              child: const Text('Skip Task'),
            ),
          ],

          const SizedBox(height: 24),

          // Help Text
          Card(
            color: Colors.grey[100],
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      Text(
                        'How to submit',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Record your video\n'
                    '2. Upload to YouTube, Google Photos, or another hosting service\n'
                    '3. Copy the shareable link\n'
                    '4. Paste the link above and submit',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSkipConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Skip Task?'),
        content: const Text(
          'Are you sure you want to skip this task? You won\'t be able to earn points for it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<TaskExecutionBloc>().add(
                    SkipTask(
                      gameId: widget.gameId,
                      taskIndex: widget.taskIndex,
                      userId: widget.userId,
                    ),
                  );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return 'just now';
    }

    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes minute${minutes > 1 ? 's' : ''} ago';
    }

    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hour${hours > 1 ? 's' : ''} ago';
    }

    final days = difference.inDays;
    return '$days day${days > 1 ? 's' : ''} ago';
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return 'Expired';
    }

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} remaining';
    }

    if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} remaining';
    }

    if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} remaining';
    }

    return 'Less than a minute';
  }
}