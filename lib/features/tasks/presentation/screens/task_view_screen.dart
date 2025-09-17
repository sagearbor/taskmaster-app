import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/task.dart';
import '../../../../core/models/submission.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../widgets/video_task_submission.dart';
import '../widgets/puzzle_task_submission.dart';

class TaskViewScreen extends StatelessWidget {
  final String gameId;
  final Task task;
  final bool canSubmit;

  const TaskViewScreen({
    super.key,
    required this.gameId,
    required this.task,
    this.canSubmit = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(task.title),
        elevation: 0,
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! AuthAuthenticated) {
            return const Center(
              child: Text('Authentication required'),
            );
          }

          final currentUser = authState.user;
          final userSubmission = task.getSubmissionByUser(currentUser.id);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Task Description Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: task.isVideoTask 
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                task.isVideoTask ? Icons.videocam : Icons.quiz,
                                color: task.isVideoTask ? Colors.red[700] : Colors.blue[700],
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    task.isVideoTask ? 'Video Task' : 'Puzzle Task',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: task.isVideoTask ? Colors.red[700] : Colors.blue[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            task.description,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Submission Status
                if (userSubmission != null) ...[
                  Card(
                    color: userSubmission.isJudged 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                userSubmission.isJudged 
                                    ? Icons.check_circle 
                                    : Icons.schedule,
                                color: userSubmission.isJudged 
                                    ? Colors.green[700] 
                                    : Colors.blue[700],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  userSubmission.isJudged 
                                      ? 'Your submission has been judged!'
                                      : 'Your submission is waiting to be judged',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: userSubmission.isJudged 
                                        ? Colors.green[700] 
                                        : Colors.blue[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (userSubmission.isJudged) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Score: ',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  '${userSubmission.score} points',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Submission Interface
                if (canSubmit) ...[
                  if (task.isVideoTask)
                    VideoTaskSubmission(
                      task: task,
                      gameId: gameId,
                      existingSubmission: userSubmission,
                    )
                  else
                    PuzzleTaskSubmission(
                      task: task,
                      gameId: gameId,
                      existingSubmission: userSubmission,
                    ),
                ] else ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Submissions are not allowed at this time',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Other Submissions (for judge view)
                if (task.submissions.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Submissions (${task.submissions.length})',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...task.submissions.map((submission) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: submission.isJudged 
                                      ? Colors.green 
                                      : Colors.grey[400],
                                  child: Icon(
                                    submission.isJudged 
                                        ? Icons.check 
                                        : Icons.schedule,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text('Player ${submission.userId.substring(0, 8)}'),
                                subtitle: submission.hasVideoUrl 
                                    ? Text('Video: ${submission.videoUrl}')
                                    : Text('Answer: ${submission.textAnswer}'),
                                trailing: submission.isJudged 
                                    ? Chip(
                                        label: Text('${submission.score} pts'),
                                        backgroundColor: Colors.green.withOpacity(0.1),
                                      )
                                    : const Text('Pending'),
                                onTap: submission.hasVideoUrl
                                    ? () {
                                        // TODO: Open video player or external link
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Open: ${submission.videoUrl}'),
                                          ),
                                        );
                                      }
                                    : null,
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}