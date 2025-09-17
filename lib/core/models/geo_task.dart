import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'task.dart';

class GeoLocation extends Equatable {
  final double latitude;
  final double longitude;
  final String? name;
  final String? description;
  final double radiusMeters;

  const GeoLocation({
    required this.latitude,
    required this.longitude,
    this.name,
    this.description,
    this.radiusMeters = 50.0,
  });

  factory GeoLocation.fromMap(Map<String, dynamic> map) {
    return GeoLocation(
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      name: map['name'] as String?,
      description: map['description'] as String?,
      radiusMeters: map['radiusMeters'] as double? ?? 50.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'name': name,
      'description': description,
      'radiusMeters': radiusMeters,
    };
  }

  double distanceTo(GeoLocation other) {
    return Geolocator.distanceBetween(
      latitude,
      longitude,
      other.latitude,
      other.longitude,
    );
  }

  bool isWithinRadius(GeoLocation other) {
    return distanceTo(other) <= radiusMeters;
  }

  @override
  List<Object?> get props => [latitude, longitude, name, description, radiusMeters];
}

class GeoTask extends Equatable {
  final String id;
  final Task task;
  final GeoLocation targetLocation;
  final bool requiresExactLocation;
  final List<String> completedByPlayers;
  final DateTime? expiresAt;
  final Map<String, GeoLocation> playerCheckIns;

  const GeoTask({
    required this.id,
    required this.task,
    required this.targetLocation,
    this.requiresExactLocation = true,
    this.completedByPlayers = const [],
    this.expiresAt,
    this.playerCheckIns = const {},
  });

  factory GeoTask.fromMap(Map<String, dynamic> map) {
    return GeoTask(
      id: map['id'] as String,
      task: Task.fromMap(map['task'] as Map<String, dynamic>),
      targetLocation: GeoLocation.fromMap(map['targetLocation'] as Map<String, dynamic>),
      requiresExactLocation: map['requiresExactLocation'] as bool? ?? true,
      completedByPlayers: List<String>.from(map['completedByPlayers'] ?? []),
      expiresAt: map['expiresAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['expiresAt'] as int)
          : null,
      playerCheckIns: (map['playerCheckIns'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, GeoLocation.fromMap(value as Map<String, dynamic>)),
      ) ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task': task.toMap(),
      'targetLocation': targetLocation.toMap(),
      'requiresExactLocation': requiresExactLocation,
      'completedByPlayers': completedByPlayers,
      'expiresAt': expiresAt?.millisecondsSinceEpoch,
      'playerCheckIns': playerCheckIns.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
    };
  }

  GeoTask copyWith({
    String? id,
    Task? task,
    GeoLocation? targetLocation,
    bool? requiresExactLocation,
    List<String>? completedByPlayers,
    DateTime? expiresAt,
    Map<String, GeoLocation>? playerCheckIns,
  }) {
    return GeoTask(
      id: id ?? this.id,
      task: task ?? this.task,
      targetLocation: targetLocation ?? this.targetLocation,
      requiresExactLocation: requiresExactLocation ?? this.requiresExactLocation,
      completedByPlayers: completedByPlayers ?? this.completedByPlayers,
      expiresAt: expiresAt ?? this.expiresAt,
      playerCheckIns: playerCheckIns ?? this.playerCheckIns,
    );
  }

  bool isPlayerAtLocation(String playerId, GeoLocation currentLocation) {
    if (requiresExactLocation) {
      return targetLocation.isWithinRadius(currentLocation);
    }
    return targetLocation.distanceTo(currentLocation) <= 100; // 100m tolerance for non-exact
  }

  GeoTask checkInPlayer(String playerId, GeoLocation location) {
    final newCheckIns = Map<String, GeoLocation>.from(playerCheckIns);
    newCheckIns[playerId] = location;
    
    List<String> newCompleted = List<String>.from(completedByPlayers);
    if (isPlayerAtLocation(playerId, location) && !newCompleted.contains(playerId)) {
      newCompleted.add(playerId);
    }
    
    return copyWith(
      playerCheckIns: newCheckIns,
      completedByPlayers: newCompleted,
    );
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get hasBeenCompleted => completedByPlayers.isNotEmpty;
  
  double distanceFromTarget(GeoLocation currentLocation) {
    return targetLocation.distanceTo(currentLocation);
  }

  String getDistanceDescription(GeoLocation currentLocation) {
    final distance = distanceFromTarget(currentLocation);
    
    if (distance < 10) return "You're very close!";
    if (distance < 50) return "You're getting warmer...";
    if (distance < 100) return "You're in the right area";
    if (distance < 500) return "Keep looking around";
    if (distance < 1000) return "You're within 1km";
    return "${(distance / 1000).toStringAsFixed(1)}km away";
  }

  @override
  List<Object?> get props => [
        id,
        task,
        targetLocation,
        requiresExactLocation,
        completedByPlayers,
        expiresAt,
        playerCheckIns,
      ];
}

class GeoTaskLibrary {
  static final List<Map<String, dynamic>> _geoTaskTemplates = [
    // Park/Outdoor tasks
    {
      'task': Task(
        id: 'geo_park_1',
        title: 'Playground Detective',
        description: 'Find a playground and recreate your favorite childhood game for 2 minutes',
        taskType: TaskType.video,
        submissions: [],
      ),
      'locationType': 'park',
      'locationName': 'Local Park',
      'radiusMeters': 100.0,
    },
    
    {
      'task': Task(
        id: 'geo_park_2',
        title: 'Nature Scavenger',
        description: 'Collect 5 different types of leaves and arrange them by size',
        taskType: TaskType.video,
        submissions: [],
      ),
      'locationType': 'park',
      'locationName': 'Park or Garden',
      'radiusMeters': 150.0,
    },

    // Coffee shop/Cafe tasks
    {
      'task': Task(
        id: 'geo_cafe_1',
        title: 'Barista Challenge',
        description: 'Order the most complicated drink you can think of and tip the barista with a compliment',
        taskType: TaskType.video,
        submissions: [],
      ),
      'locationType': 'cafe',
      'locationName': 'Coffee Shop',
      'radiusMeters': 25.0,
    },

    {
      'task': Task(
        id: 'geo_cafe_2',
        title: 'Latte Art Appreciation',
        description: 'Find someone with latte art and convince them to let you take an artistic photo of it',
        taskType: TaskType.video,
        submissions: [],
      ),
      'locationType': 'cafe',
      'locationName': 'Coffee Shop or Cafe',
      'radiusMeters': 25.0,
    },

    // Bookstore tasks
    {
      'task': Task(
        id: 'geo_bookstore_1',
        title: 'Literary Speed Dating',
        description: 'Find 3 books you\'ve never heard of and give a 30-second review of each based on the cover',
        taskType: TaskType.video,
        submissions: [],
      ),
      'locationType': 'bookstore',
      'locationName': 'Bookstore or Library',
      'radiusMeters': 50.0,
    },

    // Grocery store tasks
    {
      'task': Task(
        id: 'geo_grocery_1',
        title: 'Produce Comedian',
        description: 'Make up names for 5 different fruits or vegetables and explain what each one does',
        taskType: TaskType.video,
        submissions: [],
      ),
      'locationType': 'grocery',
      'locationName': 'Grocery Store',
      'radiusMeters': 50.0,
    },

    {
      'task': Task(
        id: 'geo_grocery_2',
        title: 'Aisle Dancer',
        description: 'Dance your way through at least 3 different aisles while "shopping"',
        taskType: TaskType.video,
        submissions: [],
      ),
      'locationType': 'grocery',
      'locationName': 'Grocery Store',
      'radiusMeters': 50.0,
    },

    // Public transport tasks
    {
      'task': Task(
        id: 'geo_transport_1',
        title: 'Commuter Connection',
        description: 'Strike up a friendly conversation with a stranger on public transport',
        taskType: TaskType.video,
        submissions: [],
      ),
      'locationType': 'transport',
      'locationName': 'Bus Stop or Train Station',
      'radiusMeters': 75.0,
    },

    // Street/Urban tasks
    {
      'task': Task(
        id: 'geo_street_1',
        title: 'Street Art Curator',
        description: 'Find interesting street art or architecture and give it an art gallery-style description',
        taskType: TaskType.video,
        submissions: [],
      ),
      'locationType': 'street',
      'locationName': 'Urban Area',
      'radiusMeters': 200.0,
    },

    {
      'task': Task(
        id: 'geo_street_2',
        title: 'Crosswalk Choreographer',
        description: 'Create a mini dance routine that you can complete while crossing a pedestrian crossing',
        taskType: TaskType.video,
        submissions: [],
      ),
      'locationType': 'street',
      'locationName': 'Pedestrian Crossing',
      'radiusMeters': 50.0,
    },

    // Restaurant tasks
    {
      'task': Task(
        id: 'geo_restaurant_1',
        title: 'Menu Mystery',
        description: 'Ask the server to recommend their most unusual dish and explain why you should try it',
        taskType: TaskType.video,
        submissions: [],
      ),
      'locationType': 'restaurant',
      'locationName': 'Restaurant',
      'radiusMeters': 25.0,
    },

    // Museum/Cultural site tasks
    {
      'task': Task(
        id: 'geo_museum_1',
        title: 'Exhibit Narrator',
        description: 'Pick an exhibit and create your own audio tour commentary for it',
        taskType: TaskType.video,
        submissions: [],
      ),
      'locationType': 'museum',
      'locationName': 'Museum or Gallery',
      'radiusMeters': 100.0,
    },

    // Beach/Waterfront tasks
    {
      'task': Task(
        id: 'geo_beach_1',
        title: 'Sand Architect',
        description: 'Build the most creative sand structure you can in 10 minutes',
        taskType: TaskType.video,
        submissions: [],
      ),
      'locationType': 'beach',
      'locationName': 'Beach or Waterfront',
      'radiusMeters': 100.0,
    },
  ];

  static GeoTask createGeoTask({
    required GeoLocation targetLocation,
    String? locationType,
    bool requiresExactLocation = true,
    Duration? timeLimit,
  }) {
    // Filter templates by location type if specified
    final templates = locationType != null 
        ? _geoTaskTemplates.where((t) => t['locationType'] == locationType).toList()
        : _geoTaskTemplates;
    
    if (templates.isEmpty) {
      throw ArgumentError('No tasks available for location type: $locationType');
    }

    final selectedTemplate = templates[DateTime.now().millisecondsSinceEpoch % templates.length];
    final task = selectedTemplate['task'] as Task;
    
    return GeoTask(
      id: 'geo_${DateTime.now().millisecondsSinceEpoch}',
      task: task.copyWith(id: 'geo_task_${DateTime.now().millisecondsSinceEpoch}'),
      targetLocation: targetLocation.copyWith(
        name: targetLocation.name ?? selectedTemplate['locationName'] as String?,
        radiusMeters: selectedTemplate['radiusMeters'] as double? ?? targetLocation.radiusMeters,
      ),
      requiresExactLocation: requiresExactLocation,
      expiresAt: timeLimit != null ? DateTime.now().add(timeLimit) : null,
    );
  }

  static List<String> get availableLocationTypes {
    return _geoTaskTemplates
        .map((template) => template['locationType'] as String)
        .toSet()
        .toList();
  }

  static List<Map<String, dynamic>> getTasksForLocationType(String locationType) {
    return _geoTaskTemplates
        .where((template) => template['locationType'] == locationType)
        .toList();
  }
}

extension GeoLocationExtensions on GeoLocation {
  GeoLocation copyWith({
    double? latitude,
    double? longitude,
    String? name,
    String? description,
    double? radiusMeters,
  }) {
    return GeoLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      name: name ?? this.name,
      description: description ?? this.description,
      radiusMeters: radiusMeters ?? this.radiusMeters,
    );
  }
}