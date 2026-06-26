import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/services/ar/ar_capability_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/repositories/game_repository.dart';
import '../bloc/ar_task_bloc.dart';
import '../widgets/ar_unsupported_view.dart';

/// Entry point for an AR task. Runs the capability check and routes to the
/// right state UI. When the device is capable it currently shows an INTERNAL
/// SCAFFOLD (not a finished game): a dev-only "Simulate score" button proves
/// the AR -> scoreboard loop end-to-end with zero AR plugin. The real Balloon
/// Pop rendering is a later phase that needs a physical device.
class ARTaskScreen extends StatelessWidget {
  final String gameId;
  final int taskIndex;

  const ARTaskScreen({
    super.key,
    required this.gameId,
    required this.taskIndex,
  });

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthAuthenticated ? authState.user.id : '';

    return BlocProvider(
      create: (_) => ArTaskBloc(
        capabilityService: sl<ArCapabilityService>(),
        gameRepository: sl<GameRepository>(),
        gameId: gameId,
        taskIndex: taskIndex,
        userId: userId,
      )..add(const ArCheckRequested()),
      child: const _ARTaskView(),
    );
  }
}

class _ARTaskView extends StatelessWidget {
  const _ARTaskView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AR Task')),
      body: BlocConsumer<ArTaskBloc, ArTaskState>(
        listener: (context, state) {
          if (state is ArTaskSubmitted) {
            // The full loop is done — return to the game so the scoreboard
            // (driven by the game stream) reflects the new score.
            Navigator.of(context).maybePop();
          }
        },
        builder: (context, state) {
          final bloc = context.read<ArTaskBloc>();

          if (state is ArTaskChecking || state is ArTaskSubmitting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ArTaskUnsupported) {
            return ArUnsupportedView(
              reason: state.reason,
              onSkip: () => bloc.add(const ArSkipRequested()),
              onUpdateArCore: state.reason == ArSupport.needsArCoreUpdate
                  ? () => bloc.add(const ArCheckRequested())
                  : null,
            );
          }

          if (state is ArTaskPermissionDenied) {
            return ArUnsupportedView(
              reason: ArSupport.cameraDenied,
              onSkip: () => bloc.add(const ArSkipRequested()),
              onOpenSettings: () => sl<ArCapabilityService>().openSettings(),
            );
          }

          if (state is ArTaskError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => bloc.add(const ArCheckRequested()),
              onSkip: () => bloc.add(const ArSkipRequested()),
            );
          }

          // Ready / Playing / Finished — the capable path.
          return _ReadyScaffold(state: state);
        },
      ),
    );
  }
}

/// The capable-device scaffold. Intentionally NOT a finished AR game — it is an
/// internal harness that proves the score write-back loop.
class _ReadyScaffold extends StatelessWidget {
  final ArTaskState state;

  const _ReadyScaffold({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bloc = context.read<ArTaskBloc>();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.view_in_ar, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'AR ready',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your device supports AR. The Balloon Pop mini-game renders here '
              'in a later phase (needs a physical device).',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),

            // ---- DEV-ONLY SCAFFOLD CONTROL -----------------------------------
            // Temporary internal tool: proves the AR -> scoreboard loop without
            // any AR plugin. Removed before shipping; never shown in release.
            if (kDebugMode) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  border: Border.all(color: Colors.amber),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      'DEV SCAFFOLD ONLY — not a real game',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => bloc.add(
                        const ArScoreSubmitted(score: 7, rawResult: 7),
                      ),
                      icon: const Icon(Icons.bolt),
                      label: const Text('Simulate score (dev)'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Players can always opt out.
            TextButton.icon(
              onPressed: () => bloc.add(const ArSkipRequested()),
              icon: const Icon(Icons.skip_next),
              label: const Text('Skip this task'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSkip;

  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.red),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            const SizedBox(height: 8),
            TextButton(onPressed: onSkip, child: const Text('Skip this task')),
          ],
        ),
      ),
    );
  }
}
