import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/service_locator.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../data/datasources/nearby_permissions.dart';
import '../../domain/repositories/telephone_repository.dart';
import 'offline_telephone_screens.dart';
import 'telephone_session_screen.dart';

/// Entry point for Drawing Telephone: pick a name, then create a new game or
/// join one with an invite code. Identity is a fresh per-session id, so the
/// same person can open two browser tabs and play as two distinct players —
/// which is exactly how this gets verified.
class TelephoneStartScreen extends StatefulWidget {
  const TelephoneStartScreen({super.key});

  @override
  State<TelephoneStartScreen> createState() => _TelephoneStartScreenState();
}

class _TelephoneStartScreenState extends State<TelephoneStartScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _uuid = const Uuid();
  bool _busy = false;

  TelephoneRepository get _repo => sl<TelephoneRepository>();

  @override
  void initState() {
    super.initState();
    // Pre-fill with the signed-in display name when we have one.
    final auth = sl<AuthRepository>();
    auth.getCurrentUser().then((user) {
      if (mounted && user != null && _nameController.text.isEmpty) {
        _nameController.text = user.displayName;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String get _name {
    final n = _nameController.text.trim();
    return n.isEmpty ? 'Player' : n;
  }

  /// Firestore rules require an authenticated user. Make sure we have one
  /// (anonymous is fine) before any read/write so real play never silently
  /// fails on permissions.
  Future<void> _ensureSignedIn() async {
    final auth = sl<AuthRepository>();
    if (auth.getCurrentUserId() == null) {
      await auth.signInAnonymously();
    }
  }

  Future<void> _create() async {
    if (_nameController.text.trim().isEmpty) {
      _toast('Enter your name first');
      return;
    }
    setState(() => _busy = true);
    try {
      await _ensureSignedIn();
      final playerId = _uuid.v4();
      final sessionId = await _repo.createSession(
        creatorUid: playerId,
        creatorName: _name,
      );
      _open(sessionId, playerId);
    } catch (e) {
      _toast('Could not create game. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      _toast('Enter the 6-character invite code');
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      _toast('Enter your name first');
      return;
    }
    setState(() => _busy = true);
    try {
      await _ensureSignedIn();
      final playerId = _uuid.v4();
      final sessionId = await _repo.joinSession(
        inviteCode: code,
        uid: playerId,
        displayName: _name,
      );
      _open(sessionId, playerId);
    } catch (e) {
      _toast(_friendly(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Offline / no-internet play over Google Nearby Connections (Bluetooth +
  /// Wi-Fi Direct). Android only — no account or invite code needed.
  void _hostOffline() {
    if (_nameController.text.trim().isEmpty) {
      _toast('Enter your name first');
      return;
    }
    if (!NearbyPermissions.isSupportedPlatform) {
      _toast('Offline nearby play is only available on Android.');
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => OfflineHostScreen(displayName: _name),
    ));
  }

  void _joinOffline() {
    if (_nameController.text.trim().isEmpty) {
      _toast('Enter your name first');
      return;
    }
    if (!NearbyPermissions.isSupportedPlatform) {
      _toast('Offline nearby play is only available on Android.');
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => OfflineJoinScreen(displayName: _name),
    ));
  }

  void _open(String sessionId, String playerId) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TelephoneSessionScreen(
          sessionId: sessionId,
          playerId: playerId,
          displayName: _name,
        ),
      ),
    );
  }

  String _friendly(Object e) {
    final t = e.toString().toLowerCase();
    if (t.contains('not found')) {
      return 'No game with that code. Double-check and try again.';
    }
    if (t.contains('already started')) {
      return 'That game has already started.';
    }
    if (t.contains('full')) return 'That game is full (8 players max).';
    return 'Could not join. Please try again.';
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Drawing Telephone')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('🎨 Drawing Telephone',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Write a prompt, draw the prompt before you, guess the drawing '
                'before you — then laugh at how it mutated. 2–8 players.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Your name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _busy ? null : _create,
                icon: const Icon(Icons.add),
                label: const Text('Create a new game'),
              ),
              const SizedBox(height: 28),
              Row(children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or join one',
                      style: theme.textTheme.bodySmall),
                ),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                maxLength: 6,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Invite code',
                  hintText: '6-character code',
                  prefixIcon: Icon(Icons.tag),
                ),
                style: const TextStyle(
                    letterSpacing: 3, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _busy ? null : _join,
                icon: const Icon(Icons.group_add),
                label: const Text('Join game'),
              ),
              if (NearbyPermissions.isSupportedPlatform) ...[
                const SizedBox(height: 28),
                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('no wifi? play offline',
                        style: theme.textTheme.bodySmall),
                  ),
                  const Expanded(child: Divider()),
                ]),
                const SizedBox(height: 8),
                Text(
                  'On a plane or off the grid — connect Android phones directly '
                  'over Bluetooth & Wi-Fi Direct. No internet needed.',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: _busy ? null : _hostOffline,
                  icon: const Icon(Icons.wifi_tethering),
                  label: const Text('Play offline (nearby)'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _joinOffline,
                  icon: const Icon(Icons.travel_explore),
                  label: const Text('Find nearby game'),
                ),
              ],
              if (_busy) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
