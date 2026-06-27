import '../../../../core/models/telephone_session.dart';

/// Domain API for the Drawing Telephone game. UI talks only to this; the
/// concrete impl wires it to either the mock or Firestore data source.
abstract class TelephoneRepository {
  /// Live state for a session (null once it stops existing).
  Stream<TelephoneSession?> watchSession(String sessionId);

  /// Create a new session in the lobby owned by [creatorUid]. Returns the new
  /// session id. [creatorUid] is a per-session player id, NOT the auth uid, so
  /// two tabs / guests stay distinct.
  Future<String> createSession({
    required String creatorUid,
    required String creatorName,
    String? gameName,
  });

  /// Join the lobby of the session with [inviteCode]. Returns the session id.
  /// Throws if no session matches or the game already started.
  Future<String> joinSession({
    required String inviteCode,
    required String uid,
    required String displayName,
  });

  /// Lock the roster and begin play (creator action).
  Future<void> startGame(String sessionId);

  /// Submit the current step's contribution for [uid]. [content] is text for a
  /// prompt/guess or JSON strokes for a drawing.
  Future<void> submitEntry({
    required String sessionId,
    required String uid,
    required String content,
  });
}
