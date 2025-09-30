import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/repositories/game_repository.dart';
import '../bloc/judging_bloc.dart';
import '../bloc/judging_event.dart';
import '../bloc/judging_state.dart';
import 'task_scoreboard_screen.dart';
import '../bloc/game_detail_bloc.dart';

class SubmissionReviewScreen extends StatelessWidget {
  final String gameId;
  final int taskIndex;

  const SubmissionReviewScreen({
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
      child: SubmissionReviewView(
        gameId: gameId,
        taskIndex: taskIndex,
      ),
    );
  }
}

class SubmissionReviewView extends StatefulWidget {
  final String gameId;
  final int taskIndex;

  const SubmissionReviewView({
    super.key,
    required this.gameId,
    required this.taskIndex,
  });

  @override
  State<SubmissionReviewView> createState() => _SubmissionReviewViewState();
}

class _SubmissionReviewViewState extends State<SubmissionReviewView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open URL: $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Submissions'),
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

          if (state is JudgingCompleted) {
            // Get the game from GameDetailBloc to navigate to scoreboard
            final gameDetailState = context.read<GameDetailBloc>().state;
            if (gameDetailState is GameDetailLoaded) {
              final game = gameDetailState.game;
              final task = game.tasks[state.taskIndex];

              // Calculate task scores from the judging state
              // We need to get the scores from the previous JudgingLoaded state
              Map<String, int> taskScores = {};
              Map<String, int> previousTotals = {};

              // Get scores from the submissions
              for (var player in game.players) {
                previousTotals[player.userId] = player.totalScore;
                // Find the submission for this player
                final submission = task.submissions.firstWhere(
                  (sub) => sub.playerId == player.userId,
                  orElse: () => task.submissions.first,
                );
                taskScores[player.userId] = submission.score ?? 0;
              }

              // Navigate to task scoreboard
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => TaskScoreboardScreen(
                    game: game,
                    completedTask: task,
                    taskIndex: state.taskIndex,
                    taskScores: taskScores,
                    previousTotals: previousTotals,
                  ),
                ),
              );
            } else {
              // Fallback to original behavior
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            }
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
            // Filter to only show submitted submissions
            final submittedSubmissions = state.submissions
                .where((s) => s.status.hasSubmitted)
                .toList();

            if (submittedSubmissions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No submissions to review',
                      style: Theme.of(context).textTheme.titleLarge,
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

            return Column(
              children: [
                // Progress indicator
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Scored: ${state.scoredCount} of ${submittedSubmissions.length}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (state.canFinish)
                        ElevatedButton.icon(
                          onPressed: () {
                            _showFinishConfirmation(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.check),
                          label: const Text('Finish'),
                        ),
                    ],
                  ),
                ),

                // PageView for submissions
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: submittedSubmissions.length,
                    onPageChanged: (index) {
                      setState(() {});
                    },
                    itemBuilder: (context, index) {
                      final submission = submittedSubmissions[index];
                      return _buildSubmissionCard(context, state, submission, index, submittedSubmissions.length);
                    },
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSubmissionCard(
    BuildContext context,
    JudgingLoaded state,
    SubmissionData submission,
    int index,
    int total,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Navigation indicator
          Center(
            child: Text(
              'Submission ${index + 1} of $total',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
          const SizedBox(height: 16),

          // Player Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      submission.playerName.isNotEmpty
                          ? submission.playerName[0].toUpperCase()
                          : 'P',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    submission.playerName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (submission.score != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber),
                          const SizedBox(width: 8),
                          Text(
                            'Scored: ${submission.score} pts',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.green[700],
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

          // Video Link Card
          if (submission.submissionUrl != null)
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
                          'Video Submission',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _openUrl(submission.submissionUrl!),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open Video'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      submission.submissionUrl!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Scoring Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Score This Submission',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildScoreButton(context, submission, 1),
                      _buildScoreButton(context, submission, 2),
                      _buildScoreButton(context, submission, 3),
                      _buildScoreButton(context, submission, 4),
                      _buildScoreButton(context, submission, 5),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: submission.skipped
                        ? null
                        : () {
                            context.read<JudgingBloc>().add(
                                  SkipSubmission(playerId: submission.playerId),
                                );
                            // Move to next page
                            if (_pageController.page! < total - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Skip This Submission'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Navigation Buttons
          Row(
            children: [
              if (index > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                  ),
                ),
              if (index > 0 && index < total - 1) const SizedBox(width: 8),
              if (index < total - 1)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreButton(BuildContext context, SubmissionData submission, int score) {
    final isSelected = submission.score == score;
    return Column(
      children: [
        IconButton(
          onPressed: () {
            context.read<JudgingBloc>().add(
                  ScoreSubmission(
                    playerId: submission.playerId,
                    score: score,
                  ),
                );
            // Auto-advance to next submission after short delay
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_pageController.hasClients) {
                final currentPage = _pageController.page?.round() ?? 0;
                final state = context.read<JudgingBloc>().state;
                if (state is JudgingLoaded) {
                  final total = state.submissions.where((s) => s.status.hasSubmitted).length;
                  if (currentPage < total - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                }
              }
            });
          },
          iconSize: 48,
          icon: Icon(
            isSelected ? Icons.star : Icons.star_border,
            color: isSelected ? Colors.amber : Colors.grey,
          ),
        ),
        Text(
          '$score pt${score == 1 ? '' : 's'}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.amber : Colors.grey,
              ),
        ),
      ],
    );
  }

  void _showFinishConfirmation(BuildContext context) {
    final state = context.read<JudgingBloc>().state as JudgingLoaded;

    // Edge case: Judge hasn't scored any submissions
    if (state.scoredCount == 0) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('No Scores Given'),
          icon: const Icon(Icons.warning, color: Colors.orange, size: 48),
          content: const Text(
            'You haven\'t scored any submissions yet. '
            'Please score at least one submission before finishing.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
      return;
    }

    // Edge case: Judge hasn't scored all submissions (warning)
    final unscored = state.submissions.where((s) => s.status.hasSubmitted && s.score == null).length;
    final warningMessage = unscored > 0
        ? 'You have scored ${state.scoredCount} submissions but $unscored are still unscored. '
        : 'You have scored ${state.scoredCount} submissions. ';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Finish Judging?'),
        content: Text(
          '$warningMessage'
          'This will finalize the scores and update player totals.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          if (unscored > 0)
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Review Unscored ($unscored)'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<JudgingBloc>().add(const FinishJudging());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }
}