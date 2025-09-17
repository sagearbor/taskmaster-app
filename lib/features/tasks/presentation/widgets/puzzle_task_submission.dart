import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/models/task.dart';
import '../../../../core/models/submission.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../games/presentation/bloc/game_detail_bloc.dart';

class PuzzleTaskSubmission extends StatefulWidget {
  final Task task;
  final String gameId;
  final Submission? existingSubmission;

  const PuzzleTaskSubmission({
    super.key,
    required this.task,
    required this.gameId,
    this.existingSubmission,
  });

  @override
  State<PuzzleTaskSubmission> createState() => _PuzzleTaskSubmissionState();
}

class _PuzzleTaskSubmissionState extends State<PuzzleTaskSubmission> {
  final _formKey = GlobalKey<FormState>();
  final _answerController = TextEditingController();
  bool _isSubmitting = false;
  static const Uuid _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    if (widget.existingSubmission != null && widget.existingSubmission!.hasTextAnswer) {
      _answerController.text = widget.existingSubmission!.textAnswer!;
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  String? _validateAnswer(String? value) {
    if (value == null || value.isEmpty) {
      return 'Answer is required';
    }
    if (value.length < 1) {
      return 'Please provide an answer';
    }
    return null;
  }

  bool _checkAnswer(String answer) {
    if (widget.task.puzzleAnswer == null) return false;
    
    final correctAnswer = widget.task.puzzleAnswer!.toLowerCase().trim();
    final userAnswer = answer.toLowerCase().trim();
    
    // Exact match
    if (userAnswer == correctAnswer) return true;
    
    // Remove common variations (a, an, the)
    final cleanedCorrect = correctAnswer.replaceAll(RegExp(r'\b(a|an|the)\b'), '').trim();
    final cleanedUser = userAnswer.replaceAll(RegExp(r'\b(a|an|the)\b'), '').trim();
    
    return cleanedUser == cleanedCorrect;
  }

  Future<void> _submitAnswer() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userAnswer = _answerController.text.trim();
      final isCorrect = _checkAnswer(userAnswer);
      
      final submission = Submission(
        id: _uuid.v4(),
        userId: authState.user.id,
        videoUrl: null,
        textAnswer: userAnswer,
        score: isCorrect ? 5 : 0, // Auto-score puzzle tasks
        isJudged: true, // Auto-judge puzzle tasks
        submittedAt: DateTime.now(),
      );

      context.read<GameDetailBloc>().add(
        SubmitTaskAnswer(
          gameId: widget.gameId,
          taskId: widget.task.id,
          submission: submission,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCorrect 
                ? 'Correct! You earned 5 points!' 
                : 'Incorrect answer. Better luck next time!'),
            backgroundColor: isCorrect ? Colors.green : Colors.orange,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit answer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasExistingSubmission = widget.existingSubmission != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.quiz,
                    color: Colors.blue[700],
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasExistingSubmission ? 'Update Your Answer' : 'Submit Your Answer',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.purple[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Puzzle Task',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Think carefully and provide your best answer. This task will be automatically scored.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.purple[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _answerController,
                decoration: const InputDecoration(
                  labelText: 'Your Answer',
                  hintText: 'Type your answer here...',
                  prefixIcon: Icon(Icons.edit),
                  helperText: 'Provide your best answer to the puzzle',
                ),
                validator: _validateAnswer,
                enabled: !_isSubmitting && !hasExistingSubmission,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),
              
              if (hasExistingSubmission) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.existingSubmission!.score > 0 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.existingSubmission!.score > 0 
                          ? Colors.green 
                          : Colors.orange,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            widget.existingSubmission!.score > 0 
                                ? Icons.check_circle 
                                : Icons.close_rounded,
                            color: widget.existingSubmission!.score > 0 
                                ? Colors.green[700] 
                                : Colors.orange[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.existingSubmission!.score > 0 
                                  ? 'Correct Answer!' 
                                  : 'Incorrect Answer',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: widget.existingSubmission!.score > 0 
                                    ? Colors.green[700] 
                                    : Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Score: ',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${widget.existingSubmission!.score} points',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: widget.existingSubmission!.score > 0 
                                  ? Colors.green[700] 
                                  : Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your answer: "${widget.existingSubmission!.textAnswer}"',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Puzzle tasks can only be answered once',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitAnswer,
                  icon: _isSubmitting 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    _isSubmitting ? 'Submitting...' : 'Submit Answer',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '⚠️ You can only submit once for puzzle tasks',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}