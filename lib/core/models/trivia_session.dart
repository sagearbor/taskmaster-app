import 'package:equatable/equatable.dart';

import 'session_mode.dart';
import 'trivia_questions.dart';

/// Lifecycle of a Trivia Buzzer session.
///
/// * [lobby]   — players are joining; host has not started.
/// * [playing] — a question is live; players buzz by tapping a choice.
/// * [reveal]  — the current question is locked; show the right answer, who
///               scored, and the running scoreboard.
/// * [done]    — every question has been played; show the final scoreboard.
enum TriviaPhase { lobby, playing, reveal, done }

/// A player in a Trivia Buzzer session. Identity is a per-session id (not the
/// Firebase auth uid) so two browser tabs / guests are still distinct players —
/// matching the Drawing Telephone convention.
class TriviaPlayer extends Equatable {
  final String uid;
  final String displayName;
  final int score;

  const TriviaPlayer({
    required this.uid,
    required this.displayName,
    this.score = 0,
  });

  TriviaPlayer copyWith({String? displayName, int? score}) => TriviaPlayer(
        uid: uid,
        displayName: displayName ?? this.displayName,
        score: score ?? this.score,
      );

  factory TriviaPlayer.fromMap(Map<String, dynamic> map) {
    return TriviaPlayer(
      uid: map['uid'] as String,
      displayName: map['displayName'] as String? ?? 'Player',
      score: map['score'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() =>
      {'uid': uid, 'displayName': displayName, 'score': score};

  @override
  List<Object?> get props => [uid, displayName, score];
}

/// One player's answer to the CURRENT question. The host (or local transport)
/// stamps [atMillis] in arrival order — that ordering is what decides the
/// "first correct" winner, so it must come from a single authoritative clock.
class TriviaBuzz extends Equatable {
  final String uid;
  final int choiceIndex;
  final int atMillis;

  const TriviaBuzz({
    required this.uid,
    required this.choiceIndex,
    required this.atMillis,
  });

  factory TriviaBuzz.fromMap(Map<String, dynamic> map) {
    return TriviaBuzz(
      uid: map['uid'] as String,
      choiceIndex: map['choiceIndex'] as int? ?? -1,
      atMillis: map['atMillis'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() =>
      {'uid': uid, 'choiceIndex': choiceIndex, 'atMillis': atMillis};

  @override
  List<Object?> get props => [uid, choiceIndex, atMillis];
}

/// The live state of a Trivia Buzzer game.
///
/// Like [TelephoneSession], this model owns ALL of the game's pure logic —
/// buzz capture, first-correct selection, scoring, and question advance — so
/// the rules are identical whether they run against the mock data source
/// (tests), a Firestore transaction, or a host-authoritative local (Nearby /
/// Bluetooth) transport. Data sources / transports stay dumb: they persist
/// [toMap]/[fromMap] and apply transforms; they never re-implement game rules.
///
/// ## Round flow
/// The host drives transitions; every device converges on the synced document:
///
///   lobby --started()--> playing
///   playing --withBuzz()/revealed()--> reveal   (scores the question once)
///   reveal --advanceQuestion()--> playing | done
///
/// During [playing], each player may buzz exactly once via [withBuzz]; the
/// first buzz locks their answer. Once everyone has buzzed the round auto-flips
/// to [reveal], or the host can flip early with [revealed]. The first buzz that
/// chose the correct answer (lowest [TriviaBuzz.atMillis], ties broken by
/// arrival order) wins the points for that question.
class TriviaSession extends Equatable {
  /// Minimum players needed to start. Trivia is playable solo (you can still
  /// answer and score), so this is intentionally lenient.
  static const int minPlayers = 1;

  /// Default number of questions a freshly created game plays.
  static const int defaultQuestionCount = 10;

  final String id;
  final String gameName;
  final SessionMode mode;
  final String inviteCode;
  final String creatorUid;
  final DateTime createdAt;
  final List<TriviaPlayer> players;
  final TriviaPhase phase;

  /// The questions this game will play, by [TriviaQuestion.id], in order. Fixed
  /// at creation so every device resolves the same questions from the bundled
  /// bank. Its length is the total number of rounds.
  final List<String> questionIds;

  /// 0-based index into [questionIds] of the question currently in play (or, in
  /// [TriviaPhase.reveal], the one just revealed).
  final int currentQuestionIndex;

  /// Buzzes for the CURRENT question, in arrival order. Reset to empty whenever
  /// the game advances to the next question.
  final List<TriviaBuzz> buzzes;

  // ---- Scoring config (synced so all devices score identically) ----
  /// Base points awarded to the first correct buzzer.
  final int basePoints;

  /// When true, the first correct buzzer earns an extra [speedBonus] if they
  /// were also the very first player to buzz at all (fastest correct = more).
  final bool speedScoring;

  /// Extra points for a speed-bonus win (see [speedScoring]).
  final int speedBonus;

  const TriviaSession({
    required this.id,
    required this.gameName,
    required this.mode,
    required this.inviteCode,
    required this.creatorUid,
    required this.createdAt,
    required this.players,
    required this.phase,
    required this.questionIds,
    required this.currentQuestionIndex,
    required this.buzzes,
    this.basePoints = 100,
    this.speedScoring = true,
    this.speedBonus = 50,
  });

  /// A fresh session sitting in the lobby with just the creator present and the
  /// question line-up already chosen.
  factory TriviaSession.create({
    required String id,
    required String gameName,
    required String inviteCode,
    required String creatorUid,
    required String creatorName,
    required List<String> questionIds,
    DateTime? createdAt,
    int basePoints = 100,
    bool speedScoring = true,
    int speedBonus = 50,
  }) {
    return TriviaSession(
      id: id,
      gameName: gameName,
      mode: SessionMode.party,
      inviteCode: inviteCode,
      creatorUid: creatorUid,
      createdAt: createdAt ?? DateTime.now(),
      players: [TriviaPlayer(uid: creatorUid, displayName: creatorName)],
      phase: TriviaPhase.lobby,
      questionIds: questionIds,
      currentQuestionIndex: 0,
      buzzes: const [],
      basePoints: basePoints,
      speedScoring: speedScoring,
      speedBonus: speedBonus,
    );
  }

  factory TriviaSession.fromMap(Map<String, dynamic> map) {
    return TriviaSession(
      id: map['id'] as String,
      gameName: map['gameName'] as String? ?? 'Trivia Buzzer',
      mode: SessionMode.fromName(map['mode'] as String?,
          fallback: SessionMode.party),
      inviteCode: map['inviteCode'] as String? ?? '',
      creatorUid: map['creatorUid'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      players: (map['players'] as List<dynamic>?)
              ?.map((e) =>
                  TriviaPlayer.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      phase: TriviaPhase.values.firstWhere(
        (p) => p.name == map['phase'],
        orElse: () => TriviaPhase.lobby,
      ),
      questionIds: (map['questionIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      currentQuestionIndex: map['currentQuestionIndex'] as int? ?? 0,
      buzzes: (map['buzzes'] as List<dynamic>?)
              ?.map((e) =>
                  TriviaBuzz.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      basePoints: map['basePoints'] as int? ?? 100,
      speedScoring: map['speedScoring'] as bool? ?? true,
      speedBonus: map['speedBonus'] as int? ?? 50,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'gameName': gameName,
        'mode': mode.name,
        'inviteCode': inviteCode,
        'creatorUid': creatorUid,
        'createdAt': createdAt.toIso8601String(),
        'players': players.map((p) => p.toMap()).toList(),
        'phase': phase.name,
        'questionIds': questionIds,
        'currentQuestionIndex': currentQuestionIndex,
        'buzzes': buzzes.map((b) => b.toMap()).toList(),
        'basePoints': basePoints,
        'speedScoring': speedScoring,
        'speedBonus': speedBonus,
      };

  TriviaSession copyWith({
    String? gameName,
    SessionMode? mode,
    List<TriviaPlayer>? players,
    TriviaPhase? phase,
    int? currentQuestionIndex,
    List<TriviaBuzz>? buzzes,
  }) {
    return TriviaSession(
      id: id,
      gameName: gameName ?? this.gameName,
      mode: mode ?? this.mode,
      inviteCode: inviteCode,
      creatorUid: creatorUid,
      createdAt: createdAt,
      players: players ?? this.players,
      phase: phase ?? this.phase,
      questionIds: questionIds,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      buzzes: buzzes ?? this.buzzes,
      basePoints: basePoints,
      speedScoring: speedScoring,
      speedBonus: speedBonus,
    );
  }

  // ---- Derived helpers -----------------------------------------------------

  int get playerCount => players.length;

  bool get isInLobby => phase == TriviaPhase.lobby;
  bool get isPlaying => phase == TriviaPhase.playing;
  bool get isRevealing => phase == TriviaPhase.reveal;
  bool get isDone => phase == TriviaPhase.done;

  /// Total number of questions (rounds) in this game.
  int get totalQuestions => questionIds.length;

  /// 1-based question number for display ("Question 3 of 10").
  int get questionNumber => currentQuestionIndex + 1;

  /// True when the current question is the last one.
  bool get isLastQuestion => currentQuestionIndex >= totalQuestions - 1;

  int orderIndexOf(String uid) => players.indexWhere((p) => p.uid == uid);

  bool hasPlayer(String uid) => orderIndexOf(uid) != -1;

  /// The bundled question now in play, or null if the id is unknown / there are
  /// no questions. Callers must tolerate null.
  TriviaQuestion? get currentQuestion {
    if (currentQuestionIndex < 0 || currentQuestionIndex >= totalQuestions) {
      return null;
    }
    return triviaQuestionById(questionIds[currentQuestionIndex]);
  }

  bool hasBuzzed(String uid) => buzzes.any((b) => b.uid == uid);

  /// True once every player has buzzed the current question.
  bool get allBuzzed => isPlaying && buzzes.length >= playerCount;

  /// Buzzes for the current question sorted by arrival ([atMillis]); a stable
  /// sort, so equal timestamps keep their insertion (arrival) order.
  List<TriviaBuzz> get buzzesByArrival {
    final sorted = [...buzzes];
    sorted.sort((a, b) => a.atMillis.compareTo(b.atMillis));
    return sorted;
  }

  /// The first buzz that chose the correct answer, or null if nobody did.
  TriviaBuzz? get winningBuzz {
    final correct = currentQuestion?.correctIndex;
    if (correct == null) return null;
    for (final b in buzzesByArrival) {
      if (b.choiceIndex == correct) return b;
    }
    return null;
  }

  /// uid of the player who scored the current question, or null if nobody did.
  String? get winnerUid => winningBuzz?.uid;

  /// Players ordered for a scoreboard: highest score first, ties broken by
  /// name then uid for a stable, deterministic ordering.
  List<TriviaPlayer> get scoreboard {
    final ranked = [...players];
    ranked.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      final byName = a.displayName.toLowerCase().compareTo(
            b.displayName.toLowerCase(),
          );
      if (byName != 0) return byName;
      return a.uid.compareTo(b.uid);
    });
    return ranked;
  }

  // ---- Pure state transitions ----------------------------------------------

  /// Add a player in the lobby. Idempotent — a uid already present is returned
  /// unchanged, so joining twice (or racing the host) is safe.
  TriviaSession withPlayerJoined(String uid, String displayName) {
    if (!isInLobby || hasPlayer(uid)) return this;
    return copyWith(players: [
      ...players,
      TriviaPlayer(uid: uid, displayName: displayName),
    ]);
  }

  /// Begin play: reset scores, clear buzzes, and reveal the first question.
  /// Throws if called with too few players. Idempotent-safe: calling it once
  /// the game has left the lobby is a no-op.
  TriviaSession started() {
    if (!isInLobby) return this;
    if (playerCount < minPlayers) {
      throw StateError('Need at least $minPlayers player(s) to start');
    }
    if (totalQuestions == 0) {
      throw StateError('No questions configured for this game');
    }
    return copyWith(
      phase: TriviaPhase.playing,
      currentQuestionIndex: 0,
      buzzes: const [],
      players: players.map((p) => p.copyWith(score: 0)).toList(),
    );
  }

  /// Record one player's buzz for the current question.
  ///
  /// Appends the buzz (locking that player's answer — a second buzz from the
  /// same player is ignored), and once EVERY player has buzzed, auto-advances
  /// to [TriviaPhase.reveal], scoring the question. Safe to retry / run inside a
  /// transaction. [atMillis] must come from the host's authoritative clock so
  /// "first correct" is well-defined across devices.
  TriviaSession withBuzz(String uid, int choiceIndex, int atMillis) {
    if (!isPlaying) return this;
    if (!hasPlayer(uid)) return this;
    if (hasBuzzed(uid)) return this;

    final newBuzzes = [
      ...buzzes,
      TriviaBuzz(uid: uid, choiceIndex: choiceIndex, atMillis: atMillis),
    ];

    if (newBuzzes.length >= playerCount) {
      return _scoredAndRevealed(newBuzzes);
    }
    return copyWith(buzzes: newBuzzes);
  }

  /// Host action: lock the current question now (without waiting for stragglers)
  /// and reveal the answer + award points. No-op outside [TriviaPhase.playing],
  /// so it can't double-score a question already in reveal.
  TriviaSession revealed() {
    if (!isPlaying) return this;
    return _scoredAndRevealed(buzzes);
  }

  /// Award points for [roundBuzzes] to the first correct buzzer and flip to
  /// reveal. Pure: builds a fresh players list (no mutation of `this`).
  TriviaSession _scoredAndRevealed(List<TriviaBuzz> roundBuzzes) {
    final revealed = copyWith(phase: TriviaPhase.reveal, buzzes: roundBuzzes);
    final winner = revealed.winningBuzz;
    if (winner == null) return revealed;

    final sorted = revealed.buzzesByArrival;
    final wasFirstOverall =
        sorted.isNotEmpty && sorted.first.uid == winner.uid;
    final points = basePoints + (speedScoring && wasFirstOverall ? speedBonus : 0);

    final newPlayers = revealed.players
        .map((p) => p.uid == winner.uid
            ? p.copyWith(score: p.score + points)
            : p)
        .toList();
    return revealed.copyWith(players: newPlayers);
  }

  /// Move from reveal to the next question, or to [TriviaPhase.done] after the
  /// last one. No-op unless currently revealing.
  TriviaSession advanceQuestion() {
    if (!isRevealing) return this;
    final next = currentQuestionIndex + 1;
    if (next >= totalQuestions) {
      return copyWith(phase: TriviaPhase.done, buzzes: const []);
    }
    return copyWith(
      phase: TriviaPhase.playing,
      currentQuestionIndex: next,
      buzzes: const [],
    );
  }

  @override
  List<Object?> get props => [
        id,
        gameName,
        mode,
        inviteCode,
        creatorUid,
        createdAt,
        players,
        phase,
        questionIds,
        currentQuestionIndex,
        buzzes,
        basePoints,
        speedScoring,
        speedBonus,
      ];
}
