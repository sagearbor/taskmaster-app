import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/models/player_task_status.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/repositories/game_repository.dart';
import '../bloc/task_execution_bloc.dart';
import '../bloc/task_execution_event.dart';
import '../bloc/task_execution_state.dart';
import '../widgets/submission_progress_widget.dart';
import '../widgets/task_timer_widget.dart';

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
    if (url.isEmpty) return false;

    // Basic URL validation
    final urlPattern = RegExp(
      r'^https?://',
      caseSensitive: false,
    );

    if (!urlPattern.hasMatch(url)) return false;

    // Check for common video hosting platforms
    final validDomains = [
      'youtube.com',
      'youtu.be',
      'photos.google.com',
      'photos.app.goo.gl',
      'drive.google.com',
      'dropbox.com',
      'vimeo.com',
      'streamable.com',
    ];

    return validDomains.any((domain) => url.toLowerCase().contains(domain));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Submission successful! ✅'),
                backgroundColor: Colors.green,
              ),
            );

            // Navigate to video viewing screen after short delay
            Future.delayed(const Duration(seconds: 1), () {
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed(
                  '/video-viewing',
                  arguments: {
                    'gameId': state.gameId,
                    'taskIndex': state.taskIndex,
                  },
                );
              }
            });
          }
        },
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
            // Check if user already submitted
            if (state.hasUserSubmitted) {
              return _buildAlreadySubmittedView(context, state);
            }

            return _buildTaskExecutionForm(context, state);
          }

          return const SizedBox.shrink();
        },
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
              Text(
                'Your submission:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  state.userStatus!.submissionUrl!,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
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
                  Navigator.of(context).pushNamed(
                    '/video-viewing',
                    arguments: {
                      'gameId': widget.gameId,
                      'taskIndex': widget.taskIndex,
                    },
                  );
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