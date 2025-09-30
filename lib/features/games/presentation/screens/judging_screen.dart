import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/repositories/game_repository.dart';
import '../bloc/judging_bloc.dart';
import '../bloc/judging_event.dart';
import '../bloc/judging_state.dart';
import 'submission_review_screen.dart';

class JudgingScreen extends StatelessWidget {
  final String gameId;
  final int taskIndex;

  const JudgingScreen({
    super.key,
    required this.gameId,
    required this.taskIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => JudgingBloc(
        gameRepository: sl<GameRepository>(),
      )..add(LoadSubmissions(
          gameId: gameId,
          taskIndex: taskIndex,
        )),
      child: JudgingView(
        gameId: gameId,
        taskIndex: taskIndex,
      ),
    );
  }
}

class JudgingView extends StatelessWidget {
  final String gameId;
  final int taskIndex;

  const JudgingView({
    super.key,
    required this.gameId,
    required this.taskIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Judge Submissions'),
      ),
      body: BlocConsumer<JudgingBloc, JudgingState>(
        listener: (context, state) {
          if (state is JudgingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is JudgingLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is JudgingError) {
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

          if (state is JudgingLoaded) {
            return _buildJudgingContent(context, state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildJudgingContent(BuildContext context, JudgingLoaded state) {
    return SingleChildScrollView(
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
                  Text(
                    state.taskTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.taskDescription,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Submission Status Card
          Card(
            color: state.allSubmitted
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    state.allSubmitted ? Icons.check_circle : Icons.schedule,
                    size: 48,
                    color: state.allSubmitted ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.allSubmitted
                        ? 'All Submitted - Ready to Judge!'
                        : 'Waiting for Submissions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: state.allSubmitted ? Colors.green[700] : Colors.orange[700],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${state.submittedCount} of ${state.totalSubmissions} players submitted',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: state.submittedCount / state.totalSubmissions,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      state.allSubmitted ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Submissions List
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Submissions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...state.submissions.map((submission) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: submission.status.hasSubmitted
                              ? Colors.green
                              : Colors.grey[400],
                          child: Text(
                            submission.playerName.isNotEmpty
                                ? submission.playerName[0].toUpperCase()
                                : 'P',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(submission.playerName),
                        subtitle: Text(
                          submission.status.hasSubmitted
                              ? 'Submitted'
                              : 'Not submitted yet',
                          style: TextStyle(
                            color: submission.status.hasSubmitted
                                ? Colors.green[700]
                                : Colors.grey[600],
                          ),
                        ),
                        trailing: submission.status.hasSubmitted
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : Icon(Icons.schedule, color: Colors.grey[400]),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          if (state.submittedCount > 0) ...[
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SubmissionReviewScreen(
                      gameId: gameId,
                      taskIndex: taskIndex,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.gavel),
              label: Text(
                state.allSubmitted ? 'Judge All Submissions' : 'Judge Now (${state.submittedCount} available)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            if (!state.allSubmitted)
              Text(
                'You can judge now or wait for all players to submit',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
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
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No submissions yet. Players will see this task and can submit their videos.',
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
  }
}