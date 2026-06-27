import '../../../../core/models/trivia_session.dart';

/// Domain API for the Trivia Buzzer game. UI / bloc talks only to this; the
/// concrete impl wires it to either the mock data source or, later, a
/// host-authoritative local (Nearby / Bluetooth) transport. The bloc never
/// touches a backend directly, so swapping transports is a DI change only.
abstract class TriviaRepository {
  /// Live state for a session (null once it stops existing).
  Stream<TriviaSession?> watchSession(String sessionId);

  /// Create a new session in the lobby owned by [creatorUid]. Picks the
  /// question line-up from the bundled bank. Returns the new session id.
  /// [creatorUid] is a per-session player id, NOT the auth uid, so two tabs /
  /// guests stay distinct.
  Future<String> createSession({
    required String creatorUid,
    required String creatorName,
    String? gameName,
    int questionCount,
  });

  /// Join the lobby of the session with [inviteCode]. Returns the session id.
  /// Throws if no session matches or the game already started.
  Future<String> joinSession({
    required String inviteCode,
    required String uid,
    required String displayName,
  });

  /// Lock the roster and reveal the first question (host action).
  Future<void> startGame(String sessionId);

  /// Record [uid]'s buzz (their chosen [choiceIndex]) for the current question.
  /// [atMillis] defaults to now; the host clock decides "first correct".
  Future<void> buzz({
    required String sessionId,
    required String uid,
    required int choiceIndex,
    int? atMillis,
  });

  /// Host action: reveal the current question's answer now, scoring it.
  Future<void> reveal(String sessionId);

  /// Host action: advance from reveal to the next question (or finish).
  Future<void> advanceQuestion(String sessionId);
}
