import 'package:equatable/equatable.dart';
import 'task.dart';

enum ARTaskType {
  objectPlacement,
  objectInteraction,
  scavenger,
  measurement,
  decoration,
  navigation,
  animation,
}

class ARInstructions extends Equatable {
  final String setupText;
  final List<String> steps;
  final String completionCriteria;
  final Map<String, dynamic> arParameters;

  const ARInstructions({
    required this.setupText,
    required this.steps,
    required this.completionCriteria,
    this.arParameters = const {},
  });

  factory ARInstructions.fromMap(Map<String, dynamic> map) {
    return ARInstructions(
      setupText: map['setupText'] as String,
      steps: List<String>.from(map['steps'] ?? []),
      completionCriteria: map['completionCriteria'] as String,
      arParameters: Map<String, dynamic>.from(map['arParameters'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'setupText': setupText,
      'steps': steps,
      'completionCriteria': completionCriteria,
      'arParameters': arParameters,
    };
  }

  @override
  List<Object?> get props => [setupText, steps, completionCriteria, arParameters];
}

class ARTask extends Equatable {
  final String id;
  final Task baseTask;
  final ARTaskType arType;
  final ARInstructions arInstructions;
  final List<String> requiredPermissions;
  final bool requiresMotionTracking;
  final bool requiresPlaneDetection;
  final bool requiresLightEstimation;
  final Map<String, String> arAssets; // Asset paths for 3D models, textures, etc.

  const ARTask({
    required this.id,
    required this.baseTask,
    required this.arType,
    required this.arInstructions,
    this.requiredPermissions = const ['camera'],
    this.requiresMotionTracking = true,
    this.requiresPlaneDetection = false,
    this.requiresLightEstimation = false,
    this.arAssets = const {},
  });

  factory ARTask.fromMap(Map<String, dynamic> map) {
    return ARTask(
      id: map['id'] as String,
      baseTask: Task.fromMap(map['baseTask'] as Map<String, dynamic>),
      arType: ARTaskType.values.firstWhere(
        (e) => e.name == map['arType'],
        orElse: () => ARTaskType.objectPlacement,
      ),
      arInstructions: ARInstructions.fromMap(map['arInstructions'] as Map<String, dynamic>),
      requiredPermissions: List<String>.from(map['requiredPermissions'] ?? ['camera']),
      requiresMotionTracking: map['requiresMotionTracking'] as bool? ?? true,
      requiresPlaneDetection: map['requiresPlaneDetection'] as bool? ?? false,
      requiresLightEstimation: map['requiresLightEstimation'] as bool? ?? false,
      arAssets: Map<String, String>.from(map['arAssets'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'baseTask': baseTask.toMap(),
      'arType': arType.name,
      'arInstructions': arInstructions.toMap(),
      'requiredPermissions': requiredPermissions,
      'requiresMotionTracking': requiresMotionTracking,
      'requiresPlaneDetection': requiresPlaneDetection,
      'requiresLightEstimation': requiresLightEstimation,
      'arAssets': arAssets,
    };
  }

  ARTask copyWith({
    String? id,
    Task? baseTask,
    ARTaskType? arType,
    ARInstructions? arInstructions,
    List<String>? requiredPermissions,
    bool? requiresMotionTracking,
    bool? requiresPlaneDetection,
    bool? requiresLightEstimation,
    Map<String, String>? arAssets,
  }) {
    return ARTask(
      id: id ?? this.id,
      baseTask: baseTask ?? this.baseTask,
      arType: arType ?? this.arType,
      arInstructions: arInstructions ?? this.arInstructions,
      requiredPermissions: requiredPermissions ?? this.requiredPermissions,
      requiresMotionTracking: requiresMotionTracking ?? this.requiresMotionTracking,
      requiresPlaneDetection: requiresPlaneDetection ?? this.requiresPlaneDetection,
      requiresLightEstimation: requiresLightEstimation ?? this.requiresLightEstimation,
      arAssets: arAssets ?? this.arAssets,
    );
  }

  @override
  List<Object?> get props => [
        id,
        baseTask,
        arType,
        arInstructions,
        requiredPermissions,
        requiresMotionTracking,
        requiresPlaneDetection,
        requiresLightEstimation,
        arAssets,
      ];
}

class ARTaskLibrary {
  static final List<ARTask> _arTaskTemplates = [
    // Object Placement Tasks
    ARTask(
      id: 'ar_place_virtual_cake',
      baseTask: Task(
        id: 'ar_task_1',
        title: 'Virtual Cake Decorator',
        description: 'Place and decorate a virtual birthday cake in your room, then blow out the candles!',
        taskType: TaskType.video,
        submissions: [],
      ),
      arType: ARTaskType.objectPlacement,
      arInstructions: ARInstructions(
        setupText: 'Find a flat surface like a table or floor to place your virtual cake',
        steps: [
          'Point your camera at a flat surface',
          'Tap to place the birthday cake',
          'Use gestures to add candles and decorations',
          'Record yourself singing happy birthday',
          'Blow out the virtual candles to complete',
        ],
        completionCriteria: 'Successfully place cake, add decorations, and blow out candles',
        arParameters: {
          'maxCakeSize': 0.5,
          'candleCount': 5,
          'decorationOptions': ['sprinkles', 'icing', 'fruits'],
        },
      ),
      requiresPlaneDetection: true,
      arAssets: {
        'cake_model': 'assets/ar/models/birthday_cake.glb',
        'candle_model': 'assets/ar/models/candle.glb',
        'flame_particle': 'assets/ar/particles/flame.json',
      },
    ),

    // Object Interaction Tasks
    ARTask(
      id: 'ar_virtual_pet',
      baseTask: Task(
        id: 'ar_task_2',
        title: 'Virtual Pet Care',
        description: 'Summon a virtual pet and teach it three different tricks!',
        taskType: TaskType.video,
        submissions: [],
      ),
      arType: ARTaskType.objectInteraction,
      arInstructions: ARInstructions(
        setupText: 'Clear some space for your virtual pet to move around',
        steps: [
          'Tap to summon your virtual pet',
          'Use hand gestures to interact with the pet',
          'Teach it to sit by pointing down',
          'Teach it to roll over with a circular gesture',
          'Teach it to jump by pointing up',
          'Show all three tricks in sequence',
        ],
        completionCriteria: 'Successfully teach and demonstrate three different tricks',
        arParameters: {
          'petType': 'dog',
          'gestureTimeout': 5000,
          'tricksRequired': 3,
        },
      ),
      arAssets: {
        'pet_model': 'assets/ar/models/virtual_dog.glb',
        'trick_animations': 'assets/ar/animations/dog_tricks.json',
      },
    ),

    // Scavenger Hunt Tasks
    ARTask(
      id: 'ar_treasure_hunt',
      baseTask: Task(
        id: 'ar_task_3',
        title: 'AR Treasure Hunt',
        description: 'Use AR to find 5 hidden virtual treasures around your space!',
        taskType: TaskType.video,
        submissions: [],
      ),
      arType: ARTaskType.scavenger,
      arInstructions: ARInstructions(
        setupText: 'Move around your space to search for hidden virtual treasures',
        steps: [
          'Walk around and scan different surfaces',
          'Look for glowing treasure indicators',
          'Tap on treasures when you find them',
          'Collect all 5 treasures to complete the hunt',
          'Show your treasure collection at the end',
        ],
        completionCriteria: 'Find and collect all 5 hidden treasures',
        arParameters: {
          'treasureCount': 5,
          'searchRadius': 5.0,
          'treasureTypes': ['gold_coin', 'gem', 'artifact', 'scroll', 'chest'],
        },
      ),
      arAssets: {
        'treasure_models': 'assets/ar/models/treasures.glb',
        'glow_effect': 'assets/ar/effects/treasure_glow.json',
      },
    ),

    // Measurement Tasks
    ARTask(
      id: 'ar_room_measuring',
      baseTask: Task(
        id: 'ar_task_4',
        title: 'AR Interior Designer',
        description: 'Measure your room and place virtual furniture to redesign your space!',
        taskType: TaskType.video,
        submissions: [],
      ),
      arType: ARTaskType.measurement,
      arInstructions: ARInstructions(
        setupText: 'Clear your camera lens and ensure good lighting for accurate measurements',
        steps: [
          'Use AR to measure the length and width of your room',
          'Measure the height of at least one wall',
          'Place virtual furniture items (sofa, table, chair)',
          'Ensure furniture fits properly in the space',
          'Give a tour of your redesigned room',
        ],
        completionCriteria: 'Accurately measure room dimensions and place at least 3 furniture items',
        arParameters: {
          'measurementUnit': 'meters',
          'furnitureItems': ['sofa', 'table', 'chair', 'bookshelf', 'plant'],
          'minItems': 3,
        },
      ),
      requiresPlaneDetection: true,
      arAssets: {
        'furniture_models': 'assets/ar/models/furniture_pack.glb',
        'measurement_ui': 'assets/ar/ui/measurement_tools.json',
      },
    ),

    // Decoration Tasks
    ARTask(
      id: 'ar_party_decorator',
      baseTask: Task(
        id: 'ar_task_5',
        title: 'Virtual Party Planner',
        description: 'Transform your space into a party venue using AR decorations!',
        taskType: TaskType.video,
        submissions: [],
      ),
      arType: ARTaskType.decoration,
      arInstructions: ARInstructions(
        setupText: 'Choose a room or space that you want to transform into a party venue',
        steps: [
          'Add virtual balloons to the ceiling',
          'Place a disco ball in the center',
          'Add streamers along the walls',
          'Set up a virtual DJ booth',
          'Add party lights and effects',
          'Dance in your decorated space for 30 seconds',
        ],
        completionCriteria: 'Add at least 5 different decoration types and dance in the space',
        arParameters: {
          'decorationTypes': ['balloons', 'streamers', 'lights', 'disco_ball', 'dj_booth'],
          'minDecorations': 5,
          'danceTime': 30,
        },
      ),
      requiresPlaneDetection: true,
      requiresLightEstimation: true,
      arAssets: {
        'party_decorations': 'assets/ar/models/party_pack.glb',
        'light_effects': 'assets/ar/effects/party_lights.json',
        'music_visualizer': 'assets/ar/effects/visualizer.json',
      },
    ),

    // Navigation Tasks
    ARTask(
      id: 'ar_obstacle_course',
      baseTask: Task(
        id: 'ar_task_6',
        title: 'AR Obstacle Course',
        description: 'Navigate through a virtual obstacle course placed in your room!',
        taskType: TaskType.video,
        submissions: [],
      ),
      arType: ARTaskType.navigation,
      arInstructions: ARInstructions(
        setupText: 'Clear a path through your room for the obstacle course',
        steps: [
          'Set up the AR obstacle course in your space',
          'Navigate through virtual hoops without touching them',
          'Crawl under virtual barriers',
          'Jump over virtual hurdles',
          'Ring the virtual bell at the finish line',
          'Complete the course in under 2 minutes',
        ],
        completionCriteria: 'Complete the entire obstacle course without missing any obstacles',
        arParameters: {
          'courseLength': 4.0,
          'obstacleTypes': ['hoop', 'barrier', 'hurdle', 'finish_bell'],
          'timeLimit': 120,
        },
      ),
      requiresMotionTracking: true,
      requiresPlaneDetection: true,
      arAssets: {
        'obstacle_models': 'assets/ar/models/obstacles.glb',
        'success_effects': 'assets/ar/effects/success_particles.json',
      },
    ),

    // Animation Tasks
    ARTask(
      id: 'ar_puppet_show',
      baseTask: Task(
        id: 'ar_task_7',
        title: 'AR Puppet Master',
        description: 'Control virtual puppets to perform a 2-minute comedy show!',
        taskType: TaskType.video,
        submissions: [],
      ),
      arType: ARTaskType.animation,
      arInstructions: ARInstructions(
        setupText: 'Set up a virtual stage area for your puppet show',
        steps: [
          'Place the virtual puppet stage',
          'Choose 2-3 puppet characters',
          'Create a story or comedy routine',
          'Use hand gestures to control puppet movements',
          'Make the puppets interact with each other',
          'Perform for at least 2 minutes',
          'Take a bow with your puppets at the end',
        ],
        completionCriteria: 'Perform a 2-minute puppet show with character interaction',
        arParameters: {
          'stageSize': [1.5, 1.0, 0.8],
          'puppetCount': 3,
          'minPerformanceTime': 120,
          'gestureTypes': ['wave', 'point', 'grab', 'dance'],
        },
      ),
      arAssets: {
        'puppet_models': 'assets/ar/models/puppets.glb',
        'stage_model': 'assets/ar/models/puppet_stage.glb',
        'puppet_animations': 'assets/ar/animations/puppet_moves.json',
      },
    ),
  ];

  static ARTask getRandomARTask() {
    final index = DateTime.now().millisecondsSinceEpoch % _arTaskTemplates.length;
    return _arTaskTemplates[index];
  }

  static List<ARTask> getARTasksByType(ARTaskType type) {
    return _arTaskTemplates.where((task) => task.arType == type).toList();
  }

  static List<ARTask> getARTasksForBeginners() {
    return _arTaskTemplates.where((task) => 
      task.arType == ARTaskType.objectPlacement || 
      task.arType == ARTaskType.decoration).toList();
  }

  static List<ARTask> getAdvancedARTasks() {
    return _arTaskTemplates.where((task) => 
      task.arType == ARTaskType.navigation || 
      task.arType == ARTaskType.measurement || 
      task.arType == ARTaskType.animation).toList();
  }

  static bool isARSupported() {
    // This would check device capabilities
    // For now, return true for compatible devices
    return true;
  }

  static List<String> getRequiredPermissions() {
    return ['camera', 'motion'];
  }
}