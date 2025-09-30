import 'package:equatable/equatable.dart';

enum TaskPlayerState {
  not_started,
  in_progress,
  submitted,
  judged,
  skipped,
}

class PlayerTaskStatus extends Equatable {
  final String playerId;
  final TaskPlayerState state;
  final DateTime? startedAt;
  final DateTime? submittedAt;
  final String? submissionUrl;
  final int? score;
  final DateTime? scoredAt;

  const PlayerTaskStatus({
    required this.playerId,
    required this.state,
    this.startedAt,
    this.submittedAt,
    this.submissionUrl,
    this.score,
    this.scoredAt,
  });

  factory PlayerTaskStatus.fromMap(Map<String, dynamic> map) {
    return PlayerTaskStatus(
      playerId: map['playerId'] as String,
      state: TaskPlayerState.values.firstWhere(
        (e) => e.name == map['state'],
        orElse: () => TaskPlayerState.not_started,
      ),
      startedAt: map['startedAt'] != null
          ? DateTime.parse(map['startedAt'] as String)
          : null,
      submittedAt: map['submittedAt'] != null
          ? DateTime.parse(map['submittedAt'] as String)
          : null,
      submissionUrl: map['submissionUrl'] as String?,
      score: map['score'] as int?,
      scoredAt: map['scoredAt'] != null
          ? DateTime.parse(map['scoredAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'playerId': playerId,
      'state': state.name,
      'startedAt': startedAt?.toIso8601String(),
      'submittedAt': submittedAt?.toIso8601String(),
      'submissionUrl': submissionUrl,
      'score': score,
      'scoredAt': scoredAt?.toIso8601String(),
    };
  }

  PlayerTaskStatus copyWith({
    String? playerId,
    TaskPlayerState? state,
    DateTime? startedAt,
    DateTime? submittedAt,
    String? submissionUrl,
    int? score,
    DateTime? scoredAt,
  }) {
    return PlayerTaskStatus(
      playerId: playerId ?? this.playerId,
      state: state ?? this.state,
      startedAt: startedAt ?? this.startedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      submissionUrl: submissionUrl ?? this.submissionUrl,
      score: score ?? this.score,
      scoredAt: scoredAt ?? this.scoredAt,
    );
  }

  // Computed properties
  bool get hasSubmitted => state == TaskPlayerState.submitted || state == TaskPlayerState.judged;
  bool get isJudged => state == TaskPlayerState.judged;
  bool get canViewVideos => hasSubmitted; // Privacy: can only see videos after submitting

  @override
  List<Object?> get props => [
        playerId,
        state,
        startedAt,
        submittedAt,
        submissionUrl,
        score,
        scoredAt,
      ];
}