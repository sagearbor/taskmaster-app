import 'package:equatable/equatable.dart';

class Submission extends Equatable {
  final String id;
  final String userId;
  final String? videoUrl;
  final String? textAnswer;
  final int score;
  final bool isJudged;
  final DateTime submittedAt;

  const Submission({
    required this.id,
    required this.userId,
    this.videoUrl,
    this.textAnswer,
    required this.score,
    required this.isJudged,
    required this.submittedAt,
  });

  factory Submission.fromMap(Map<String, dynamic> map) {
    return Submission(
      id: map['id'] as String,
      userId: map['userId'] as String,
      videoUrl: map['videoUrl'] as String?,
      textAnswer: map['textAnswer'] as String?,
      score: map['score'] as int? ?? 0,
      isJudged: map['isJudged'] as bool? ?? false,
      submittedAt: DateTime.parse(map['submittedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'videoUrl': videoUrl,
      'textAnswer': textAnswer,
      'score': score,
      'isJudged': isJudged,
      'submittedAt': submittedAt.toIso8601String(),
    };
  }

  Submission copyWith({
    String? id,
    String? userId,
    String? videoUrl,
    String? textAnswer,
    int? score,
    bool? isJudged,
    DateTime? submittedAt,
  }) {
    return Submission(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      videoUrl: videoUrl ?? this.videoUrl,
      textAnswer: textAnswer ?? this.textAnswer,
      score: score ?? this.score,
      isJudged: isJudged ?? this.isJudged,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }

  bool get hasVideoUrl => videoUrl != null && videoUrl!.isNotEmpty;
  bool get hasTextAnswer => textAnswer != null && textAnswer!.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        userId,
        videoUrl,
        textAnswer,
        score,
        isJudged,
        submittedAt,
      ];
}