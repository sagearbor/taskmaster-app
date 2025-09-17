import 'package:equatable/equatable.dart';
import 'submission.dart';

enum TaskType { video, puzzle }

class Task extends Equatable {
  final String id;
  final String title;
  final String description;
  final TaskType taskType;
  final String? puzzleAnswer;
  final List<Submission> submissions;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.taskType,
    this.puzzleAnswer,
    required this.submissions,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      taskType: TaskType.values.firstWhere(
        (e) => e.name == map['taskType'],
        orElse: () => TaskType.video,
      ),
      puzzleAnswer: map['puzzleAnswer'] as String?,
      submissions: (map['submissions'] as List<dynamic>?)
          ?.map((e) => Submission.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'taskType': taskType.name,
      'puzzleAnswer': puzzleAnswer,
      'submissions': submissions.map((e) => e.toMap()).toList(),
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskType? taskType,
    String? puzzleAnswer,
    List<Submission>? submissions,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      taskType: taskType ?? this.taskType,
      puzzleAnswer: puzzleAnswer ?? this.puzzleAnswer,
      submissions: submissions ?? this.submissions,
    );
  }

  bool get isVideoTask => taskType == TaskType.video;
  bool get isPuzzleTask => taskType == TaskType.puzzle;

  Submission? getSubmissionByUser(String userId) {
    try {
      return submissions.firstWhere((sub) => sub.userId == userId);
    } catch (e) {
      return null;
    }
  }

  bool hasUserSubmitted(String userId) {
    return submissions.any((sub) => sub.userId == userId);
  }

  int getTotalSubmissions() => submissions.length;

  int getJudgedSubmissions() {
    return submissions.where((sub) => sub.isJudged).length;
  }

  bool get allSubmissionsJudged {
    return submissions.isNotEmpty && 
           submissions.every((sub) => sub.isJudged);
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        taskType,
        puzzleAnswer,
        submissions,
      ];
}