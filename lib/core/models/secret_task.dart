import 'package:equatable/equatable.dart';
import 'task.dart';

class SecretTask extends Equatable {
  final String id;
  final String assignedPlayerId;
  final Task task;
  final bool isRevealed;
  final bool isCompleted;
  final DateTime assignedAt;
  final DateTime? completedAt;
  final int secretPoints;
  final String? completionEvidence;

  const SecretTask({
    required this.id,
    required this.assignedPlayerId,
    required this.task,
    required this.isRevealed,
    required this.isCompleted,
    required this.assignedAt,
    this.completedAt,
    required this.secretPoints,
    this.completionEvidence,
  });

  factory SecretTask.create({
    required String assignedPlayerId,
    required Task task,
    int? secretPoints,
  }) {
    return SecretTask(
      id: 'secret_${DateTime.now().millisecondsSinceEpoch}',
      assignedPlayerId: assignedPlayerId,
      task: task,
      isRevealed: false,
      isCompleted: false,
      assignedAt: DateTime.now(),
      secretPoints: secretPoints ?? 10,
    );
  }

  factory SecretTask.fromMap(Map<String, dynamic> map) {
    return SecretTask(
      id: map['id'] as String,
      assignedPlayerId: map['assignedPlayerId'] as String,
      task: Task.fromMap(map['task'] as Map<String, dynamic>),
      isRevealed: map['isRevealed'] as bool? ?? false,
      isCompleted: map['isCompleted'] as bool? ?? false,
      assignedAt: DateTime.fromMillisecondsSinceEpoch(map['assignedAt'] as int),
      completedAt: map['completedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'] as int)
          : null,
      secretPoints: map['secretPoints'] as int? ?? 10,
      completionEvidence: map['completionEvidence'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assignedPlayerId': assignedPlayerId,
      'task': task.toMap(),
      'isRevealed': isRevealed,
      'isCompleted': isCompleted,
      'assignedAt': assignedAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'secretPoints': secretPoints,
      'completionEvidence': completionEvidence,
    };
  }

  SecretTask copyWith({
    String? id,
    String? assignedPlayerId,
    Task? task,
    bool? isRevealed,
    bool? isCompleted,
    DateTime? assignedAt,
    DateTime? completedAt,
    int? secretPoints,
    String? completionEvidence,
  }) {
    return SecretTask(
      id: id ?? this.id,
      assignedPlayerId: assignedPlayerId ?? this.assignedPlayerId,
      task: task ?? this.task,
      isRevealed: isRevealed ?? this.isRevealed,
      isCompleted: isCompleted ?? this.isCompleted,
      assignedAt: assignedAt ?? this.assignedAt,
      completedAt: completedAt ?? this.completedAt,
      secretPoints: secretPoints ?? this.secretPoints,
      completionEvidence: completionEvidence ?? this.completionEvidence,
    );
  }

  SecretTask complete({required String evidence}) {
    return copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
      completionEvidence: evidence,
    );
  }

  SecretTask reveal() {
    return copyWith(isRevealed: true);
  }

  Duration get timeSpentOnTask {
    final endTime = completedAt ?? DateTime.now();
    return endTime.difference(assignedAt);
  }

  bool get isActive => !isCompleted && !isRevealed;
  bool get isOverdue => !isCompleted && 
                        DateTime.now().difference(assignedAt).inHours > 2;

  @override
  List<Object?> get props => [
        id,
        assignedPlayerId,
        task,
        isRevealed,
        isCompleted,
        assignedAt,
        completedAt,
        secretPoints,
        completionEvidence,
      ];
}

class SecretTaskLibrary {
  static final List<Task> _secretTaskTemplates = [
    // Subtle observation tasks
    Task(
      id: 'secret_observe_1',
      title: 'Silent Observer',
      description: 'Without anyone noticing, count how many times someone says "actually" during the next 30 minutes',
      taskType: TaskType.puzzle,
      submissions: [],
    ),
    Task(
      id: 'secret_observe_2', 
      title: 'Color Detective',
      description: 'Secretly note what color shirt the person to your left is wearing and announce it at the end of the round',
      taskType: TaskType.puzzle,
      submissions: [],
    ),
    Task(
      id: 'secret_observe_3',
      title: 'Action Counter',
      description: 'Count how many times someone touches their face during this round - reveal the total at the end',
      taskType: TaskType.puzzle,
      submissions: [],
    ),

    // Stealth interaction tasks
    Task(
      id: 'secret_stealth_1',
      title: 'Secret Compliment',
      description: 'Give each player a genuine compliment without them realizing it\'s part of a secret task',
      taskType: TaskType.video,
      submissions: [],
    ),
    Task(
      id: 'secret_stealth_2',
      title: 'Invisible Influence',
      description: 'Get someone to say the word "banana" without directly asking them to',
      taskType: TaskType.video,
      submissions: [],
    ),
    Task(
      id: 'secret_stealth_3',
      title: 'Mood Lifter',
      description: 'Make someone laugh without them knowing you\'re trying to complete a task',
      taskType: TaskType.video,
      submissions: [],
    ),

    // Collection tasks
    Task(
      id: 'secret_collect_1',
      title: 'Silent Collector',
      description: 'Collect 5 different colored objects from around the room without anyone asking what you\'re doing',
      taskType: TaskType.video,
      submissions: [],
    ),
    Task(
      id: 'secret_collect_2',
      title: 'Paper Trail',
      description: 'Collect a piece of paper from 3 different players without them knowing why',
      taskType: TaskType.video,
      submissions: [],
    ),

    // Performance tasks  
    Task(
      id: 'secret_perform_1',
      title: 'Secret Dance',
      description: 'Do a little dance move every time someone says your name, but pretend it\'s just stretching',
      taskType: TaskType.video,
      submissions: [],
    ),
    Task(
      id: 'secret_perform_2',
      title: 'Accent Adventure',
      description: 'Gradually adopt a slight accent throughout the round and see if anyone notices',
      taskType: TaskType.video,
      submissions: [],
    ),
    Task(
      id: 'secret_perform_3',
      title: 'Mirror Master',
      description: 'Subtly mirror one player\'s gestures for the next 20 minutes',
      taskType: TaskType.video,
      submissions: [],
    ),

    // Memory challenges
    Task(
      id: 'secret_memory_1',
      title: 'Order Observer',
      description: 'Remember the exact order that players complete their next task and recite it perfectly',
      taskType: TaskType.puzzle,
      submissions: [],
    ),
    Task(
      id: 'secret_memory_2',
      title: 'Quote Keeper',
      description: 'Remember and repeat back exactly what the last person said word-for-word when asked',
      taskType: TaskType.puzzle,
      submissions: [],
    ),

    // Social manipulation (harmless)
    Task(
      id: 'secret_social_1',
      title: 'Question Master',
      description: 'Get every other player to ask you a question within the next 30 minutes',
      taskType: TaskType.video,
      submissions: [],
    ),
    Task(
      id: 'secret_social_2',
      title: 'Name Game',
      description: 'Get someone to say your full name without directly asking them to',
      taskType: TaskType.video,
      submissions: [],
    ),

    // Timing challenges
    Task(
      id: 'secret_timing_1',
      title: 'Perfect Timing',
      description: 'Stand up exactly 10 seconds after someone else sits down (do this 3 times)',
      taskType: TaskType.video,
      submissions: [],
    ),
    Task(
      id: 'secret_timing_2',
      title: 'Clock Watcher',
      description: 'Check the time exactly every 7 minutes for the next hour without anyone noticing the pattern',
      taskType: TaskType.puzzle,
      submissions: [],
    ),
  ];

  static Task getRandomSecretTask() {
    final now = DateTime.now();
    final index = now.millisecondsSinceEpoch % _secretTaskTemplates.length;
    final template = _secretTaskTemplates[index];
    
    return template.copyWith(
      id: 'secret_${now.millisecondsSinceEpoch}',
    );
  }

  static List<Task> getSecretTasksForGameSize(int playerCount) {
    final taskCount = (playerCount * 0.6).ceil(); // 60% of players get secret tasks
    final shuffled = List<Task>.from(_secretTaskTemplates)..shuffle();
    
    return shuffled.take(taskCount).map((template) {
      return template.copyWith(
        id: 'secret_${DateTime.now().millisecondsSinceEpoch}_${template.id}',
      );
    }).toList();
  }

  static List<Task> getSecretTasksByDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return _secretTaskTemplates.where((task) => 
          task.id.contains('observe') || task.id.contains('collect')).toList();
      case 'medium':
        return _secretTaskTemplates.where((task) => 
          task.id.contains('stealth') || task.id.contains('memory')).toList();
      case 'hard':
        return _secretTaskTemplates.where((task) => 
          task.id.contains('perform') || task.id.contains('social') || task.id.contains('timing')).toList();
      default:
        return _secretTaskTemplates;
    }
  }
}