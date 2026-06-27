import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// The locally-remembered identity for the player's active Drawing Telephone
/// session. Persisting this is what lets a user navigate away from a session
/// (or have the page reload) and come back AS THE SAME PLAYER — the host stays
/// the host — instead of accidentally re-joining as a brand-new duplicate.
class SavedTelephoneSession {
  /// Firestore document id of the session.
  final String sessionId;

  /// This device's per-session player id (NOT the auth uid).
  final String playerId;

  /// Whether this device created the session (and is therefore the host).
  final bool isHost;

  /// The shareable 6-char invite code, used to detect "join your own code".
  final String sessionCode;

  /// The display name this player joined/created with.
  final String displayName;

  const SavedTelephoneSession({
    required this.sessionId,
    required this.playerId,
    required this.isHost,
    required this.sessionCode,
    required this.displayName,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'playerId': playerId,
        'isHost': isHost,
        'sessionCode': sessionCode,
        'displayName': displayName,
      };

  factory SavedTelephoneSession.fromJson(Map<String, dynamic> json) {
    return SavedTelephoneSession(
      sessionId: json['sessionId'] as String,
      playerId: json['playerId'] as String,
      isHost: json['isHost'] as bool? ?? false,
      sessionCode: (json['sessionCode'] as String? ?? '').toUpperCase(),
      displayName: json['displayName'] as String? ?? 'Player',
    );
  }
}

/// Persists the single most-recent active Drawing Telephone identity in
/// shared_preferences. Follows the app's best-effort persistence convention
/// (see `ThemeController`): every method swallows storage errors so it can be
/// used during UI flows without ever risking a crash.
class TelephoneSessionStore {
  static const String _key = 'telephone_active_session';

  /// Remember [session] as the player's active game, replacing any previous
  /// one (we only track one active session at a time).
  Future<void> save(SavedTelephoneSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(session.toJson()));
    } catch (_) {
      // Non-fatal: resume just won't be offered next time.
    }
  }

  /// Load the saved active session, or null if none / unreadable.
  Future<SavedTelephoneSession?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return SavedTelephoneSession.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Forget the saved session entirely.
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {
      // Non-fatal.
    }
  }

  /// Forget the saved session only if it points at [sessionId]. Used to drop a
  /// stale pointer once a session is known to no longer exist, without clobbering
  /// a newer active session the user may have started since.
  Future<void> clearIfSession(String sessionId) async {
    final current = await load();
    if (current != null && current.sessionId == sessionId) {
      await clear();
    }
  }
}
