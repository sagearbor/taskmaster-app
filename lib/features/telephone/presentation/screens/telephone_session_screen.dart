import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/models/telephone_session.dart';
import '../../domain/repositories/telephone_repository.dart';
import '../bloc/telephone_bloc.dart';
import '../widgets/drawing_canvas.dart';

/// Hosts a single Drawing Telephone game and renders the right UI for the
/// current phase. [playerId] is this device's per-session identity.
class TelephoneSessionScreen extends StatelessWidget {
  final String sessionId;
  final String playerId;
  final String displayName;

  /// Optional transport override. When null the screen uses the globally
  /// registered (online/Firestore) repository; offline play passes the
  /// Nearby-backed repository here so the exact same UI runs over Bluetooth /
  /// Wi-Fi Direct.
  final TelephoneRepository? repository;

  const TelephoneSessionScreen({
    super.key,
    required this.sessionId,
    required this.playerId,
    required this.displayName,
    this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          TelephoneBloc(repository: repository ?? sl<TelephoneRepository>())
            ..add(TelephoneSubscribed(sessionId)),
      child: _SessionView(
        sessionId: sessionId,
        playerId: playerId,
      ),
    );
  }
}

class _SessionView extends StatelessWidget {
  final String sessionId;
  final String playerId;

  const _SessionView({required this.sessionId, required this.playerId});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TelephoneBloc, TelephoneState>(
      listenWhen: (prev, curr) => curr.error != null && prev.error != curr.error,
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
      },
      builder: (context, state) {
        final session = state.session;
        final title = session?.gameName ?? 'Drawing Telephone';

        Widget body;
        if (state.status == TelephoneStatus.error && session == null) {
          body = _Centered(
            child: Text(state.error ?? 'Something went wrong.'),
          );
        } else if (session == null) {
          body = const _Centered(child: CircularProgressIndicator());
        } else {
          switch (session.phase) {
            case TelephonePhase.lobby:
              body = _LobbyView(session: session, playerId: playerId);
              break;
            case TelephonePhase.playing:
              body = _PlayView(session: session, playerId: playerId);
              break;
            case TelephonePhase.reveal:
              body = _RevealView(session: session);
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
  Widget build(BuildContext context) => Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: child,
      ));
}

// ---------------------------------------------------------------------------
// Lobby
// ---------------------------------------------------------------------------

class _LobbyView extends StatelessWidget {
  final TelephoneSession session;
  final String playerId;

  const _LobbyView({required this.session, required this.playerId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCreator = session.creatorUid == playerId;
    final canStart = session.playerCount >= 2;

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
        const SizedBox(height: 24),
        Text('Players (${session.playerCount}/8)',
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
        if (isCreator)
          FilledButton.icon(
            onPressed: canStart
                ? () => context
                    .read<TelephoneBloc>()
                    .add(TelephoneStarted(session.id))
                : null,
            icon: const Icon(Icons.play_arrow),
            label: Text(canStart
                ? 'Start game'
                : 'Waiting for at least 2 players…'),
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
// Play
// ---------------------------------------------------------------------------

class _PlayView extends StatelessWidget {
  final TelephoneSession session;
  final String playerId;

  const _PlayView({required this.session, required this.playerId});

  @override
  Widget build(BuildContext context) {
    if (!session.hasPlayer(playerId)) {
      return const _Centered(
        child: Text('You are not part of this game.'),
      );
    }
    if (session.hasSubmittedCurrentStep(playerId)) {
      return _WaitingView(session: session);
    }

    final type = session.currentEntryType;
    final key = ValueKey('step-${session.step}-$playerId');
    switch (type) {
      case TelephoneEntryType.prompt:
        return _PromptInput(key: key, session: session, playerId: playerId);
      case TelephoneEntryType.drawing:
        return _DrawInput(key: key, session: session, playerId: playerId);
      case TelephoneEntryType.guess:
        return _GuessInput(key: key, session: session, playerId: playerId);
    }
  }
}

class _StepHeader extends StatelessWidget {
  final TelephoneSession session;
  final String instruction;
  const _StepHeader({required this.session, required this.instruction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Round ${session.step + 1} of ${session.totalSteps}',
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.primary)),
        const SizedBox(height: 4),
        Text(instruction,
            style:
                theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
      ],
    );
  }
}

void _submit(BuildContext context, TelephoneSession session, String uid,
    String content) {
  context.read<TelephoneBloc>().add(TelephoneEntrySubmitted(
        sessionId: session.id,
        uid: uid,
        content: content,
      ));
}

class _PromptInput extends StatefulWidget {
  final TelephoneSession session;
  final String playerId;
  const _PromptInput(
      {super.key, required this.session, required this.playerId});

  @override
  State<_PromptInput> createState() => _PromptInputState();
}

class _PromptInputState extends State<_PromptInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _StepHeader(
          session: widget.session,
          instruction: 'Write a prompt for someone to draw',
        ),
        TextField(
          controller: _controller,
          autofocus: true,
          maxLength: 120,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'e.g. A cat riding a skateboard on the moon',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _send(),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _send,
          child: const Text('Submit prompt'),
        ),
      ],
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something first!')),
      );
      return;
    }
    _submit(context, widget.session, widget.playerId, text);
  }
}

class _DrawInput extends StatefulWidget {
  final TelephoneSession session;
  final String playerId;
  const _DrawInput({super.key, required this.session, required this.playerId});

  @override
  State<_DrawInput> createState() => _DrawInputState();
}

class _DrawInputState extends State<_DrawInput> {
  final _controller = DrawingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prompt = widget.session.promptEntryForUid(widget.playerId);
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _StepHeader(
          session: widget.session,
          instruction: 'Draw this prompt',
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            prompt?.content ?? '(missing prompt)',
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 16),
        DrawingCanvas(controller: _controller),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _send,
          child: const Text('Submit drawing'),
        ),
      ],
    );
  }

  void _send() {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draw something first!')),
      );
      return;
    }
    _submit(context, widget.session, widget.playerId, _controller.toJson());
  }
}

class _GuessInput extends StatefulWidget {
  final TelephoneSession session;
  final String playerId;
  const _GuessInput({super.key, required this.session, required this.playerId});

  @override
  State<_GuessInput> createState() => _GuessInputState();
}

class _GuessInputState extends State<_GuessInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drawing = widget.session.promptEntryForUid(widget.playerId);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _StepHeader(
          session: widget.session,
          instruction: 'What is this a drawing of?',
        ),
        DrawingView(json: drawing?.content ?? ''),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          autofocus: true,
          maxLength: 120,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Your best guess…',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _send(),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _send,
          child: const Text('Submit guess'),
        ),
      ],
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Type a guess first!')),
      );
      return;
    }
    _submit(context, widget.session, widget.playerId, text);
  }
}

class _WaitingView extends StatelessWidget {
  final TelephoneSession session;
  const _WaitingView({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final waitingOn = session.players
        .where((p) => !session.hasSubmittedCurrentStep(p.uid))
        .map((p) => p.displayName)
        .toList();
    return _Centered(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hourglass_top, size: 48),
          const SizedBox(height: 16),
          Text('Submitted! 🎉',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            '${session.submittedUids.length}/${session.playerCount} done',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          if (waitingOn.isNotEmpty)
            Text('Waiting on: ${waitingOn.join(', ')}',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center),
          const SizedBox(height: 24),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reveal
// ---------------------------------------------------------------------------

class _RevealView extends StatelessWidget {
  final TelephoneSession session;
  const _RevealView({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: session.chains.length,
      itemBuilder: (context, chainIdx) {
        final chain = session.chains[chainIdx];
        if (chain.isEmpty) return const SizedBox.shrink();
        final starter = chain.first.authorName;
        return Card(
          margin: const EdgeInsets.only(bottom: 20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$starter's chain",
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Divider(),
                ...chain.map((entry) => _RevealEntry(entry: entry)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RevealEntry extends StatelessWidget {
  final TelephoneEntry entry;
  const _RevealEntry({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = switch (entry.type) {
      TelephoneEntryType.prompt => '✍️ ${entry.authorName} wrote',
      TelephoneEntryType.drawing => '🎨 ${entry.authorName} drew',
      TelephoneEntryType.guess => '💭 ${entry.authorName} guessed',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 6),
          if (entry.type == TelephoneEntryType.drawing)
            DrawingView(json: entry.content, size: 220)
          else
            Text(entry.content, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
