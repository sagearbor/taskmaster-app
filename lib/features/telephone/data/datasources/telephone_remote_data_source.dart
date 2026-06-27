/// Persistence seam for Drawing Telephone sessions. Two implementations:
/// an in-memory mock (offline dev + tests) and a Firestore one (real play).
///
/// The interface deals in raw maps and exposes an atomic [updateSession] whose
/// [transform] takes the current document and returns the next one. The mock
/// runs the transform synchronously; Firestore runs it inside a real
/// transaction. All multiplayer game rules live in the transform (built by the
/// repository from `TelephoneSession`), so concurrent submissions never clobber
/// each other regardless of backend.
abstract class TelephoneRemoteDataSource {
  /// Live updates for a single session (null once it no longer exists).
  Stream<Map<String, dynamic>?> watchSession(String sessionId);

  /// Create a new session document. [data] must include its `id`.
  Future<void> createSession(Map<String, dynamic> data);

  /// Resolve an invite code to a session id, or null if none matches.
  Future<String?> findSessionIdByCode(String inviteCode);

  /// Atomically read-modify-write a session. The [transform] receives the
  /// current document and returns the document to persist. Throws if the
  /// session does not exist.
  Future<void> updateSession(
    String sessionId,
    Map<String, dynamic> Function(Map<String, dynamic> current) transform,
  );
}
