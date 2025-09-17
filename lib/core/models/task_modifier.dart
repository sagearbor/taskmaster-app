import 'package:equatable/equatable.dart';

enum TaskModifierType {
  timeLimit,
  blindfolded,
  oneHanded,
  silent,
  backwards,
  teamwork,
  withObstacle,
  publicVoting,
  bonus,
  penalty,
}

class TaskModifier extends Equatable {
  final TaskModifierType type;
  final String name;
  final String description;
  final Map<String, dynamic> parameters;
  final int pointsMultiplier;
  final bool isActive;

  const TaskModifier({
    required this.type,
    required this.name,
    required this.description,
    required this.parameters,
    required this.pointsMultiplier,
    required this.isActive,
  });

  factory TaskModifier.timeLimit({required int seconds}) {
    return TaskModifier(
      type: TaskModifierType.timeLimit,
      name: 'Time Pressure',
      description: 'Complete this task in $seconds seconds or less',
      parameters: {'timeLimit': seconds},
      pointsMultiplier: seconds < 30 ? 3 : seconds < 60 ? 2 : 1,
      isActive: true,
    );
  }

  factory TaskModifier.blindfolded() {
    return const TaskModifier(
      type: TaskModifierType.blindfolded,
      name: 'Blindfolded',
      description: 'Complete this task while blindfolded',
      parameters: {},
      pointsMultiplier: 3,
      isActive: true,
    );
  }

  factory TaskModifier.oneHanded() {
    return const TaskModifier(
      type: TaskModifierType.oneHanded,
      name: 'One Hand Only',
      description: 'Complete this task using only one hand',
      parameters: {},
      pointsMultiplier: 2,
      isActive: true,
    );
  }

  factory TaskModifier.silent() {
    return const TaskModifier(
      type: TaskModifierType.silent,
      name: 'Silent Mode',
      description: 'Complete this task without speaking',
      parameters: {},
      pointsMultiplier: 2,
      isActive: true,
    );
  }

  factory TaskModifier.backwards() {
    return const TaskModifier(
      type: TaskModifierType.backwards,
      name: 'Backwards',
      description: 'Complete this task while moving backwards',
      parameters: {},
      pointsMultiplier: 2,
      isActive: true,
    );
  }

  factory TaskModifier.teamwork({required int teamSize}) {
    return TaskModifier(
      type: TaskModifierType.teamwork,
      name: 'Teamwork Required',
      description: 'Complete this task with exactly $teamSize people working together',
      parameters: {'teamSize': teamSize},
      pointsMultiplier: teamSize,
      isActive: true,
    );
  }

  factory TaskModifier.withObstacle({required String obstacle}) {
    return TaskModifier(
      type: TaskModifierType.withObstacle,
      name: 'Obstacle Challenge',
      description: 'Complete this task while dealing with: $obstacle',
      parameters: {'obstacle': obstacle},
      pointsMultiplier: 2,
      isActive: true,
    );
  }

  factory TaskModifier.publicVoting() {
    return const TaskModifier(
      type: TaskModifierType.publicVoting,
      name: 'Public Vote',
      description: 'All players vote on the quality of this attempt',
      parameters: {},
      pointsMultiplier: 1,
      isActive: true,
    );
  }

  factory TaskModifier.bonus({required int bonusPoints, required String condition}) {
    return TaskModifier(
      type: TaskModifierType.bonus,
      name: 'Bonus Points',
      description: 'Earn $bonusPoints extra points if: $condition',
      parameters: {'bonusPoints': bonusPoints, 'condition': condition},
      pointsMultiplier: 1,
      isActive: true,
    );
  }

  factory TaskModifier.penalty({required int penaltyPoints, required String condition}) {
    return TaskModifier(
      type: TaskModifierType.penalty,
      name: 'Penalty Risk',
      description: 'Lose $penaltyPoints points if: $condition',
      parameters: {'penaltyPoints': penaltyPoints, 'condition': condition},
      pointsMultiplier: 1,
      isActive: true,
    );
  }

  factory TaskModifier.fromMap(Map<String, dynamic> map) {
    return TaskModifier(
      type: TaskModifierType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TaskModifierType.bonus,
      ),
      name: map['name'] as String,
      description: map['description'] as String,
      parameters: Map<String, dynamic>.from(map['parameters'] ?? {}),
      pointsMultiplier: map['pointsMultiplier'] as int? ?? 1,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'name': name,
      'description': description,
      'parameters': parameters,
      'pointsMultiplier': pointsMultiplier,
      'isActive': isActive,
    };
  }

  TaskModifier copyWith({
    TaskModifierType? type,
    String? name,
    String? description,
    Map<String, dynamic>? parameters,
    int? pointsMultiplier,
    bool? isActive,
  }) {
    return TaskModifier(
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      parameters: parameters ?? this.parameters,
      pointsMultiplier: pointsMultiplier ?? this.pointsMultiplier,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object> get props => [type, name, description, parameters, pointsMultiplier, isActive];
}

class TaskModifierGenerator {
  static final List<TaskModifier Function()> _modifierFactories = [
    () => TaskModifier.timeLimit(seconds: 30),
    () => TaskModifier.timeLimit(seconds: 60),
    () => TaskModifier.timeLimit(seconds: 90),
    () => TaskModifier.blindfolded(),
    () => TaskModifier.oneHanded(),
    () => TaskModifier.silent(),
    () => TaskModifier.backwards(),
    () => TaskModifier.teamwork(teamSize: 2),
    () => TaskModifier.teamwork(teamSize: 3),
    () => TaskModifier.withObstacle(obstacle: 'wearing oven mitts'),
    () => TaskModifier.withObstacle(obstacle: 'balancing a book on your head'),
    () => TaskModifier.withObstacle(obstacle: 'hopping on one foot'),
    () => TaskModifier.withObstacle(obstacle: 'speaking in an accent'),
    () => TaskModifier.publicVoting(),
    () => TaskModifier.bonus(bonusPoints: 5, condition: 'completed with style'),
    () => TaskModifier.bonus(bonusPoints: 3, condition: 'make everyone laugh'),
    () => TaskModifier.penalty(penaltyPoints: 2, condition: 'you drop something'),
    () => TaskModifier.penalty(penaltyPoints: 1, condition: 'you say "um" or "uh"'),
  ];

  static TaskModifier generateRandom() {
    final factory = _modifierFactories[DateTime.now().millisecondsSinceEpoch % _modifierFactories.length];
    return factory();
  }

  static List<TaskModifier> generateMultiple(int count) {
    final shuffled = List<TaskModifier Function()>.from(_modifierFactories)..shuffle();
    return shuffled.take(count).map((factory) => factory()).toList();
  }

  static List<TaskModifier> getCompatibleModifiers(String taskType) {
    // Filter modifiers based on task type compatibility
    switch (taskType.toLowerCase()) {
      case 'video':
        return _modifierFactories
            .where((factory) {
              final modifier = factory();
              return modifier.type != TaskModifierType.blindfolded; // Can't watch video blindfolded
            })
            .map((factory) => factory())
            .toList();
      
      case 'physical':
        return _modifierFactories.map((factory) => factory()).toList(); // All modifiers work
      
      case 'creative':
        return _modifierFactories
            .where((factory) {
              final modifier = factory();
              return modifier.type != TaskModifierType.timeLimit || 
                     (modifier.parameters['timeLimit'] as int? ?? 60) > 60; // Need more time for creative tasks
            })
            .map((factory) => factory())
            .toList();
      
      default:
        return _modifierFactories.map((factory) => factory()).toList();
    }
  }
}