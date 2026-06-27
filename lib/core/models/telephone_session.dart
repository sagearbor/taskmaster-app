import 'package:equatable/equatable.dart';

import 'session_mode.dart';

/// What kind of contribution an entry in a chain is.
enum TelephoneEntryType { prompt, drawing, guess }

/// Lifecycle of a Drawing Telephone session.
enum TelephonePhase { lobby, playing, reveal }

/// One contribution in a chain: a starting prompt, a freehand drawing, or a
/// text guess describing the previous drawing.
///
/// [content] is plain text for [TelephoneEntryType.prompt] and
/// [TelephoneEntryType.guess], and a lightweight JSON-encoded stroke list for
/// [TelephoneEntryType.drawing] (see `DrawingCanvas`).
class TelephoneEntry extends Equatable {
  final TelephoneEntryType type;
  final String content;
  final String authorUid;
  final String authorName;

  const TelephoneEntry({
    required this.type,
    required this.content,
    required this.authorUid,
    required this.authorName,
  });

  factory TelephoneEntry.fromMap(Map<String, dynamic> map) {
    return TelephoneEntry(
      type: TelephoneEntryType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => TelephoneEntryType.prompt,
      ),
      content: map['content'] as String? ?? '',
      authorUid: map['authorUid'] as String? ?? '',
      authorName: map['authorName'] as String? ?? 'Player',
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'content': content,
        'authorUid': authorUid,
        'authorName': authorName,
      };

  @override
  List<Object?> get props => [type, content, authorUid, authorName];
}

/// A player in a Drawing Telephone session. Identity is a per-session id (not
/// the Firebase auth uid) so two browser tabs on the same anonymous account —
/// or two guests — are still distinct players.
class TelephonePlayer extends Equatable {
  final String uid;
  final String displayName;

  const TelephonePlayer({required this.uid, required this.displayName});

  factory TelephonePlayer.fromMap(Map<String, dynamic> map) {
    return TelephonePlayer(
      uid: map['uid'] as String,
      displayName: map['displayName'] as String? ?? 'Player',
    );
  }

  Map<String, dynamic> toMap() => {'uid': uid, 'displayName': displayName};

  @override
  List<Object?> get props => [uid, displayName];
}

/// The live state of a Drawing Telephone (Gartic-Phone style) game.
///
/// This model owns ALL of the game's pure logic — chain assignment, the
/// phase-gated step advance, and reveal assembly — so the rules are identical
/// whether they run against the mock data source (tests) or inside a Firestore
/// transaction (real play). Data sources stay dumb: they persist [toMap]/
/// [fromMap] and apply transforms; they never re-implement game rules.
///
/// ## Chain mechanics
/// Players are kept in a fixed order. There is exactly one chain per player;
/// chain `i` is *started* by `players[i]` (their prompt). On each [step], every
/// player contributes exactly one entry, and the chains rotate so nobody ever
/// works on their own chain twice in a row:
///
///   chainIndexForPlayer(p, step) = (p - step) mod N
///
/// So for chain `c`, the author at step `s` is `players[(c + s) mod N]`. Over
/// `N` steps each chain collects `N` entries, one from every distinct player.
///
/// Entry type by step: step 0 is a prompt; odd steps are drawings; even steps
/// (>0) are guesses → prompt → draw → guess → draw → guess …
class TelephoneSession extends Equatable {
  final String id;
  final String gameName;
  final SessionMode mode;
  final String inviteCode;
  final String creatorUid;
  final DateTime createdAt;
  final List<TelephonePlayer> players;
  final TelephonePhase phase;

  /// 0-based index of the step currently being filled while [phase] is
  /// [TelephonePhase.playing].
  final int step;

  /// One chain per player, in player order. Each chain is an ordered list of
  /// entries. Empty until the game starts.
  final List<List<TelephoneEntry>> chains;

  /// Player uids that have already submitted the CURRENT [step]. Reset to empty
  /// each time the step advances. Drives the live "waiting on N players" UI.
  final List<String> submittedUids;

  const TelephoneSession({
    required this.id,
    required this.gameName,
    required this.mode,
    required this.inviteCode,
    required this.creatorUid,
    required this.createdAt,
    required this.players,
    required this.phase,
    required this.step,
    required this.chains,
    required this.submittedUids,
  });

  /// A fresh session sitting in the lobby with just the creator present.
  factory TelephoneSession.create({
    required String id,
    required String gameName,
    required String inviteCode,
    required String creatorUid,
    required String creatorName,
    DateTime? createdAt,
  }) {
    return TelephoneSession(
      id: id,
      gameName: gameName,
      mode: SessionMode.party,
      inviteCode: inviteCode,
      creatorUid: creatorUid,
      createdAt: createdAt ?? DateTime.now(),
      players: [TelephonePlayer(uid: creatorUid, displayName: creatorName)],
      phase: TelephonePhase.lobby,
      step: 0,
      chains: const [],
      submittedUids: const [],
    );
  }

  factory TelephoneSession.fromMap(Map<String, dynamic> map) {
    return TelephoneSession(
      id: map['id'] as String,
      gameName: map['gameName'] as String? ?? 'Drawing Telephone',
      mode: SessionMode.fromName(map['mode'] as String?,
          fallback: SessionMode.party),
      inviteCode: map['inviteCode'] as String? ?? '',
      creatorUid: map['creatorUid'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      players: (map['players'] as List<dynamic>?)
              ?.map((e) =>
                  TelephonePlayer.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      phase: TelephonePhase.values.firstWhere(
        (p) => p.name == map['phase'],
        orElse: () => TelephonePhase.lobby,
      ),
      step: map['step'] as int? ?? 0,
      chains: (map['chains'] as List<dynamic>?)
              ?.map((chain) {
                // New form: each chain is {'entries': [...]}. Tolerate the old
                // raw-list form too for any in-flight sessions.
                final entries = chain is Map
                    ? (chain['entries'] as List<dynamic>? ?? const [])
                    : (chain as List<dynamic>);
                return entries
                    .map((e) => TelephoneEntry.fromMap(
                        Map<String, dynamic>.from(e as Map)))
                    .toList();
              })
              .toList() ??
          const [],
      submittedUids: (map['submittedUids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
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
        'step': step,
        // Firestore forbids an array that directly contains another array, so
        // each chain is wrapped in a map: [{entries:[...]}, {entries:[...]}].
        // Writing a raw List<List<...>> here is what caused the
        // "[cloud_firestore/unknown]" failure when starting a game.
        'chains': chains
            .map((c) => {'entries': c.map((e) => e.toMap()).toList()})
            .toList(),
        'submittedUids': submittedUids,
      };

  TelephoneSession copyWith({
    String? gameName,
    SessionMode? mode,
    List<TelephonePlayer>? players,
    TelephonePhase? phase,
    int? step,
    List<List<TelephoneEntry>>? chains,
    List<String>? submittedUids,
  }) {
    return TelephoneSession(
      id: id,
      gameName: gameName ?? this.gameName,
      mode: mode ?? this.mode,
      inviteCode: inviteCode,
      creatorUid: creatorUid,
      createdAt: createdAt,
      players: players ?? this.players,
      phase: phase ?? this.phase,
      step: step ?? this.step,
      chains: chains ?? this.chains,
      submittedUids: submittedUids ?? this.submittedUids,
    );
  }

  // ---- Derived helpers -----------------------------------------------------

  int get playerCount => players.length;

  bool get isInLobby => phase == TelephonePhase.lobby;
  bool get isPlaying => phase == TelephonePhase.playing;
  bool get isRevealing => phase == TelephonePhase.reveal;

  /// Total number of steps the game will run (one per player).
  int get totalSteps => playerCount;

  int orderIndexOf(String uid) => players.indexWhere((p) => p.uid == uid);

  bool hasPlayer(String uid) => orderIndexOf(uid) != -1;

  /// Which chain a player works on at [step] (positive modulo).
  int chainIndexForPlayer(int orderIndex, int step) {
    final n = playerCount;
    return ((orderIndex - step) % n + n) % n;
  }

  /// The entry type expected at [step]: prompt → draw → guess → draw → guess …
  static TelephoneEntryType expectedTypeForStep(int step) {
    if (step == 0) return TelephoneEntryType.prompt;
    return step.isOdd ? TelephoneEntryType.drawing : TelephoneEntryType.guess;
  }

  TelephoneEntryType get currentEntryType => expectedTypeForStep(step);

  /// True once every player has submitted the current step.
  bool get allSubmittedCurrentStep =>
      isPlaying && submittedUids.length >= playerCount;

  bool hasSubmittedCurrentStep(String uid) => submittedUids.contains(uid);

  /// The chain index [uid] is responsible for on the current step, or null if
  /// the player is not in a position to submit (not playing / not a player).
  int? assignedChainForUid(String uid) {
    if (!isPlaying) return null;
    final idx = orderIndexOf(uid);
    if (idx == -1) return null;
    return chainIndexForPlayer(idx, step);
  }

  /// The previous entry [uid] must respond to this step (the prompt to draw, or
  /// the drawing to guess). Null on the prompt step (nothing precedes it).
  TelephoneEntry? promptEntryForUid(String uid) {
    if (!isPlaying || step == 0) return null;
    final chainIdx = assignedChainForUid(uid);
    if (chainIdx == null) return null;
    final chain = chains[chainIdx];
    return chain.length >= step ? chain[step - 1] : null;
  }

  // ---- Pure state transitions ----------------------------------------------

  /// Add a player in the lobby. Idempotent — a uid already present is returned
  /// unchanged, so joining twice (or racing the host) is safe.
  TelephoneSession withPlayerJoined(String uid, String displayName) {
    if (!isInLobby || hasPlayer(uid)) return this;
    return copyWith(players: [
      ...players,
      TelephonePlayer(uid: uid, displayName: displayName),
    ]);
  }

  /// Begin play: lock the roster, create one empty chain per player, and move
  /// to step 0 (prompt). Throws if called outside the lobby or with too few
  /// players. Idempotent-safe: re-starting an already-playing game is a no-op.
  TelephoneSession started() {
    if (isPlaying || isRevealing) return this;
    if (playerCount < 2) {
      throw StateError('Need at least 2 players to start');
    }
    return copyWith(
      phase: TelephonePhase.playing,
      step: 0,
      chains: List.generate(playerCount, (_) => <TelephoneEntry>[]),
      submittedUids: const [],
    );
  }

  /// Apply one player's submission for the current step.
  ///
  /// Appends the entry to that player's assigned chain, records them as
  /// submitted, and — once ALL players have submitted — advances to the next
  /// step (clearing the submitted set) or, after the final step, flips to
  /// reveal. Re-submitting the same step is ignored (idempotent), which makes
  /// this safe to retry and safe to run inside a Firestore transaction.
  TelephoneSession withSubmission(String uid, String content) {
    if (!isPlaying) return this;
    final orderIndex = orderIndexOf(uid);
    if (orderIndex == -1) return this;
    if (hasSubmittedCurrentStep(uid)) return this;

    final chainIndex = chainIndexForPlayer(orderIndex, step);
    final player = players[orderIndex];
    final entry = TelephoneEntry(
      type: currentEntryType,
      content: content,
      authorUid: uid,
      authorName: player.displayName,
    );

    // Deep-copy chains so the transform is pure (no mutation of `this`).
    final newChains = chains
        .map((c) => List<TelephoneEntry>.from(c))
        .toList();
    newChains[chainIndex].add(entry);

    final newSubmitted = [...submittedUids, uid];

    if (newSubmitted.length >= playerCount) {
      final nextStep = step + 1;
      if (nextStep >= totalSteps) {
        return copyWith(
          chains: newChains,
          submittedUids: const [],
          phase: TelephonePhase.reveal,
          step: nextStep,
        );
      }
      return copyWith(
        chains: newChains,
        submittedUids: const [],
        step: nextStep,
      );
    }

    return copyWith(chains: newChains, submittedUids: newSubmitted);
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
        step,
        chains,
        submittedUids,
      ];
}
