import 'package:equatable/equatable.dart';
import 'task.dart';

class Timestamp extends Equatable {
  final Duration time;
  final String description;
  final String? notes;

  const Timestamp({
    required this.time,
    required this.description,
    this.notes,
  });

  factory Timestamp.fromMap(Map<String, dynamic> map) {
    return Timestamp(
      time: Duration(milliseconds: map['timeMs'] as int),
      description: map['description'] as String,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timeMs': time.inMilliseconds,
      'description': description,
      'notes': notes,
    };
  }

  String get formattedTime {
    final minutes = time.inMinutes;
    final seconds = time.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [time, description, notes];
}

class Episode extends Equatable {
  final String id;
  final String title;
  final String description;
  final List<Task> tasks;
  final List<Timestamp> timestamps;
  final Duration totalDuration;
  final DateTime createdAt;
  final String createdBy;
  final bool isPublic;
  final List<String> tags;
  final int playCount;
  final double rating;

  const Episode({
    required this.id,
    required this.title,
    required this.description,
    required this.tasks,
    required this.timestamps,
    required this.totalDuration,
    required this.createdAt,
    required this.createdBy,
    this.isPublic = false,
    this.tags = const [],
    this.playCount = 0,
    this.rating = 0.0,
  });

  factory Episode.create({
    required String title,
    required String description,
    required String createdBy,
    List<Task>? tasks,
    bool isPublic = false,
    List<String>? tags,
  }) {
    return Episode(
      id: 'episode_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      tasks: tasks ?? [],
      timestamps: [],
      totalDuration: Duration.zero,
      createdAt: DateTime.now(),
      createdBy: createdBy,
      isPublic: isPublic,
      tags: tags ?? [],
    );
  }

  factory Episode.fromMap(Map<String, dynamic> map) {
    return Episode(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      tasks: (map['tasks'] as List<dynamic>?)
          ?.map((e) => Task.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      timestamps: (map['timestamps'] as List<dynamic>?)
          ?.map((e) => Timestamp.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      totalDuration: Duration(milliseconds: map['totalDurationMs'] as int? ?? 0),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      createdBy: map['createdBy'] as String,
      isPublic: map['isPublic'] as bool? ?? false,
      tags: List<String>.from(map['tags'] ?? []),
      playCount: map['playCount'] as int? ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'tasks': tasks.map((e) => e.toMap()).toList(),
      'timestamps': timestamps.map((e) => e.toMap()).toList(),
      'totalDurationMs': totalDuration.inMilliseconds,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'isPublic': isPublic,
      'tags': tags,
      'playCount': playCount,
      'rating': rating,
    };
  }

  Episode copyWith({
    String? id,
    String? title,
    String? description,
    List<Task>? tasks,
    List<Timestamp>? timestamps,
    Duration? totalDuration,
    DateTime? createdAt,
    String? createdBy,
    bool? isPublic,
    List<String>? tags,
    int? playCount,
    double? rating,
  }) {
    return Episode(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      tasks: tasks ?? this.tasks,
      timestamps: timestamps ?? this.timestamps,
      totalDuration: totalDuration ?? this.totalDuration,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      isPublic: isPublic ?? this.isPublic,
      tags: tags ?? this.tags,
      playCount: playCount ?? this.playCount,
      rating: rating ?? this.rating,
    );
  }

  Episode addTask(Task task) {
    return copyWith(tasks: [...tasks, task]);
  }

  Episode removeTask(String taskId) {
    return copyWith(tasks: tasks.where((task) => task.id != taskId).toList());
  }

  Episode addTimestamp(Timestamp timestamp) {
    final newTimestamps = [...timestamps, timestamp];
    newTimestamps.sort((a, b) => a.time.compareTo(b.time));
    return copyWith(timestamps: newTimestamps);
  }

  Episode removeTimestamp(Timestamp timestamp) {
    return copyWith(
      timestamps: timestamps.where((t) => t != timestamp).toList(),
    );
  }

  Episode updateDuration(Duration duration) {
    return copyWith(totalDuration: duration);
  }

  Episode incrementPlayCount() {
    return copyWith(playCount: playCount + 1);
  }

  Episode updateRating(double newRating) {
    return copyWith(rating: newRating);
  }

  String get formattedDuration {
    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes % 60;
    final seconds = totalDuration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  bool get hasTimestamps => timestamps.isNotEmpty;
  bool get hasTasks => tasks.isNotEmpty;
  bool get isComplete => hasTasks && totalDuration > Duration.zero;

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        tasks,
        timestamps,
        totalDuration,
        createdAt,
        createdBy,
        isPublic,
        tags,
        playCount,
        rating,
      ];
}

class EpisodeTemplate {
  static Episode createTaskmasterClassic() {
    return Episode.create(
      title: 'Taskmaster Classic',
      description: 'A classic Taskmaster episode format with 5 varied tasks',
      createdBy: 'system',
      isPublic: true,
      tags: ['classic', 'original', 'balanced'],
    );
  }

  static Episode createQuickFire() {
    return Episode.create(
      title: 'Quick Fire Round',
      description: 'Fast-paced episode with short, snappy tasks',
      createdBy: 'system',
      isPublic: true,
      tags: ['quick', 'fast', 'energetic'],
    );
  }

  static Episode createCreativeChallenge() {
    return Episode.create(
      title: 'Creative Challenge',
      description: 'Focus on artistic and creative tasks',
      createdBy: 'system',
      isPublic: true,
      tags: ['creative', 'artistic', 'imaginative'],
    );
  }

  static Episode createPhysicalChallenge() {
    return Episode.create(
      title: 'Physical Challenge',
      description: 'Active tasks requiring movement and coordination',
      createdBy: 'system',
      isPublic: true,
      tags: ['physical', 'active', 'movement'],
    );
  }

  static Episode createTeamBuilding() {
    return Episode.create(
      title: 'Team Building',
      description: 'Collaborative tasks for team bonding',
      createdBy: 'system',
      isPublic: true,
      tags: ['team', 'collaboration', 'bonding'],
    );
  }
}