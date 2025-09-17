import 'package:equatable/equatable.dart';
import 'task.dart';

class CommunityTask extends Equatable {
  final String id;
  final String title;
  final String description;
  final TaskType taskType;
  final String? puzzleAnswer;
  final String submittedBy;
  final int upvotes;
  final DateTime createdAt;

  const CommunityTask({
    required this.id,
    required this.title,
    required this.description,
    required this.taskType,
    this.puzzleAnswer,
    required this.submittedBy,
    required this.upvotes,
    required this.createdAt,
  });

  factory CommunityTask.fromMap(Map<String, dynamic> map) {
    return CommunityTask(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      taskType: TaskType.values.firstWhere(
        (e) => e.name == map['taskType'],
        orElse: () => TaskType.video,
      ),
      puzzleAnswer: map['puzzleAnswer'] as String?,
      submittedBy: map['submittedBy'] as String,
      upvotes: map['upvotes'] as int? ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'taskType': taskType.name,
      'puzzleAnswer': puzzleAnswer,
      'submittedBy': submittedBy,
      'upvotes': upvotes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  CommunityTask copyWith({
    String? id,
    String? title,
    String? description,
    TaskType? taskType,
    String? puzzleAnswer,
    String? submittedBy,
    int? upvotes,
    DateTime? createdAt,
  }) {
    return CommunityTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      taskType: taskType ?? this.taskType,
      puzzleAnswer: puzzleAnswer ?? this.puzzleAnswer,
      submittedBy: submittedBy ?? this.submittedBy,
      upvotes: upvotes ?? this.upvotes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Task toTask() {
    return Task(
      id: id,
      title: title,
      description: description,
      taskType: taskType,
      puzzleAnswer: puzzleAnswer,
      submissions: [],
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        taskType,
        puzzleAnswer,
        submittedBy,
        upvotes,
        createdAt,
      ];
}