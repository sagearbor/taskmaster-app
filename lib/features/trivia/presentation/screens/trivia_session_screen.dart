import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/models/trivia_session.dart';
import '../../domain/repositories/trivia_repository.dart';
import '../bloc/trivia_bloc.dart';

/// Hosts a single Trivia Buzzer game and renders the right UI for the current
/// phase. [playerId] is this device's per-session identity.
class TriviaSessionScreen extends StatelessWidget {
  final String sessionId;
  final String playerId;
  final String displayName;

  const TriviaSessionScreen({
    super.key,
    required this.sessionId,
    required this.playerId,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TriviaBloc(repository: sl<TriviaRepository>())
        ..add(TriviaSubscribed(sessionId)),
      child: _SessionView(sessionId: sessionId, playerId: playerId),
    );
  }
}

class _SessionView extends StatelessWidget {
  final String sessionId;
  final String playerId;

  const _SessionView({required this.sessionId, required this.playerId});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TriviaBloc, TriviaState>(
      listenWhen: (prev, curr) =>
          curr.error != null && prev.error != curr.error,
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
      },
      builder: (context, state) {
        final session = state.session;
        final title = session?.gameName ?? 'Trivia Buzzer';

        Widget body;
        if (state.status == TriviaStatus.error && session == null) {
          body = _Centered(child: Text(state.error ?? 'Something went wrong.'));
        } else if (session == null) {
          body = const _Centered(child: CircularProgressIndicator());
        } else {
          switch (session.phase) {
            case TriviaPhase.lobby:
              body = _LobbyView(session: session, playerId: playerId);
              break;
            case TriviaPhase.playing:
              body = _PlayView(session: session, playerId: playerId);
              break;
            case TriviaPhase.reveal:
              body = _RevealView(session: session, playerId: playerId);
              break;
            case TriviaPhase.done:
              body = _DoneView(session: session, playerId: playerId);
              break;
          }
        }

        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: SafeArea(child: body),
        );
      },
    );
  }
}

class _Centered extends StatelessWidget {
  final Widget child;
  const _Centered({required this.child});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(padding: const EdgeInsets.all(24), child: child),
      );
}

bool _isHost(TriviaSession session, String playerId) =>
    session.creatorUid == playerId;

// ---------------------------------------------------------------------------
// Lobby
// ---------------------------------------------------------------------------

class _LobbyView extends StatelessWidget {
  final TriviaSession session;
  final String playerId;

  const _LobbyView({required this.session, required this.playerId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHost = _isHost(session, playerId);
    final canStart = session.playerCount >= TriviaSession.minPlayers;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Invite code', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: session.inviteCode));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invite code copied')),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              session.inviteCode,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('Tap to copy. Share it so friends can join.',
            style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Text('${session.totalQuestions} questions this game',
            style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Text('Players (${session.playerCount})',
            style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ...session.players.map((p) => ListTile(
              dense: true,
              leading: CircleAvatar(
                child: Text(p.displayName.isNotEmpty
                    ? p.displayName[0].toUpperCase()
                    : '?'),
              ),
              title: Text(p.displayName +
                  (p.uid == playerId ? ' (you)' : '') +
                  (p.uid == session.creatorUid ? '  •  host' : '')),
            )),
        const SizedBox(height: 24),
        if (isHost)
          FilledButton.icon(
            onPressed: canStart
                ? () =>
                    context.read<TriviaBloc>().add(TriviaStarted(session.id))
                : null,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start game'),
          )
        else
          Center(
            child: Text('Waiting for the host to start…',
                style: theme.textTheme.bodyMedium),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Play (question + buzz)
// ---------------------------------------------------------------------------

class _PlayView extends StatelessWidget {
  final TriviaSession session;
  final String playerId;

  const _PlayView({required this.session, required this.playerId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = session.currentQuestion;
    final isHost = _isHost(session, playerId);
    final isPlayer = session.hasPlayer(playerId);
    final hasBuzzed = session.hasBuzzed(playerId);

    if (question == null) {
      return const _Centered(child: Text('This question is unavailable.'));
    }

    final waiting = session.players
        .where((p) => !session.hasBuzzed(p.uid))
        .map((p) => p.displayName)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _RoundHeader(session: session),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(question.category.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer
                        .withOpacity(0.7),
                    letterSpacing: 1,
                  )),
              const SizedBox(height: 8),
              Text(question.question,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  )),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...List.generate(question.choices.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ChoiceButton(
              label: question.choices[i],
              index: i,
              enabled: isPlayer && !hasBuzzed,
              onTap: () => context.read<TriviaBloc>().add(
                    TriviaBuzzed(
                      sessionId: session.id,
                      uid: playerId,
                      choiceIndex: i,
                    ),
                  ),
            ),
          );
        }),
        const SizedBox(height: 8),
        if (!isPlayer)
          Text('You are spectating this game.',
              style: theme.textTheme.bodyMedium, textAlign: TextAlign.center)
        else if (hasBuzzed)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_clock,
                    color: theme.colorScheme.onSecondaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Answer locked in! Waiting for others…',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      )),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Text(
          '${session.buzzes.length}/${session.playerCount} buzzed'
          '${waiting.isEmpty ? '' : '  •  waiting on ${waiting.join(', ')}'}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        if (isHost) ...[
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () =>
                context.read<TriviaBloc>().add(TriviaRevealed(session.id)),
            icon: const Icon(Icons.visibility),
            label: const Text('Reveal answer now'),
          ),
        ],
      ],
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final int index;
  final bool enabled;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.label,
    required this.index,
    required this.enabled,
    required this.onTap,
  });

  static const _letters = ['A', 'B', 'C', 'D', 'E', 'F'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: theme.colorScheme.primary,
              child: Text(_letters[index],
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.onPrimary)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: theme.colorScheme.onSurface)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundHeader extends StatelessWidget {
  final TriviaSession session;
  const _RoundHeader({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'Question ${session.questionNumber} of ${session.totalQuestions}',
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.primary,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reveal (answer + who scored + running scoreboard)
// ---------------------------------------------------------------------------

class _RevealView extends StatelessWidget {
  final TriviaSession session;
  final String playerId;

  const _RevealView({required this.session, required this.playerId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = session.currentQuestion;
    final isHost = _isHost(session, playerId);
    final winnerUid = session.winnerUid;
    final winner = winnerUid == null
        ? null
        : session.players.firstWhere((p) => p.uid == winnerUid);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _RoundHeader(session: session),
        const SizedBox(height: 16),
        if (question != null) ...[
          Text(question.question,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle,
                    color: theme.colorScheme.onTertiaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Correct answer: ${question.correctAnswer}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            winner == null
                ? 'Nobody buzzed the right answer this round.'
                : '🏆 ${winner.displayName} got it first!',
            style: theme.textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        Text('Scoreboard', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _Scoreboard(session: session, playerId: playerId),
        const SizedBox(height: 24),
        if (isHost)
          FilledButton.icon(
            onPressed: () =>
                context.read<TriviaBloc>().add(TriviaAdvanced(session.id)),
            icon: Icon(session.isLastQuestion
                ? Icons.emoji_events
                : Icons.arrow_forward),
            label: Text(session.isLastQuestion
                ? 'See final results'
                : 'Next question'),
          )
        else
          Center(
            child: Text('Waiting for the host to continue…',
                style: theme.textTheme.bodyMedium),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Done (final scoreboard)
// ---------------------------------------------------------------------------

class _DoneView extends StatelessWidget {
  final TriviaSession session;
  final String playerId;

  const _DoneView({required this.session, required this.playerId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ranked = session.scoreboard;
    final champion = ranked.isNotEmpty ? ranked.first : null;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 8),
        Center(
          child: Text('🏆 Final results',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        if (champion != null)
          Center(
            child: Text('${champion.displayName} wins with ${champion.score}!',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.primary),
                textAlign: TextAlign.center),
          ),
        const SizedBox(height: 24),
        _Scoreboard(session: session, playerId: playerId),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.home),
          label: const Text('Back to home'),
        ),
      ],
    );
  }
}

class _Scoreboard extends StatelessWidget {
  final TriviaSession session;
  final String playerId;

  const _Scoreboard({required this.session, required this.playerId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ranked = session.scoreboard;
    return Column(
      children: List.generate(ranked.length, (i) {
        final p = ranked[i];
        final isYou = p.uid == playerId;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isYou
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text('${i + 1}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
              const SizedBox(width: 16),
              Expanded(
                child: Text(p.displayName + (isYou ? ' (you)' : ''),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isYou ? FontWeight.bold : FontWeight.normal,
                    )),
              ),
              Text('${p.score}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  )),
            ],
          ),
        );
      }),
    );
  }
}
