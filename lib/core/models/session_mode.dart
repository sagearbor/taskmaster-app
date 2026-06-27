/// Foundational `mode` tag for multiplayer / social games (see
/// docs/MULTIPLAYER_GAMES_ROADMAP.md). Additive and backward-compatible — it
/// drives lobby/task-picker filtering and tells scoring whether to compare,
/// sum, or team-aggregate. Existing single-flow games default to [solo].
enum SessionMode {
  solo,
  versus,
  coop,
  party;

  /// Parse a stored name back to a [SessionMode], tolerating unknown/missing
  /// values (e.g. documents written before this field existed) by falling back
  /// to [fallback].
  static SessionMode fromName(String? name,
      {SessionMode fallback = SessionMode.solo}) {
    return SessionMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => fallback,
    );
  }
}
