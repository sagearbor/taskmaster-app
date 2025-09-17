import 'dart:async';
import 'dart:convert';
import 'dart:math';
import '../models/task.dart';
import '../models/task_modifier.dart';

enum TaskDifficulty { easy, medium, hard, expert }
enum TaskCategory { physical, creative, mental, social, food, household, silly, challenge }

class TaskGenerationPrompt {
  final TaskCategory category;
  final TaskDifficulty difficulty;
  final TaskType taskType;
  final int playerCount;
  final List<String> availableItems;
  final String location;
  final Duration timeLimit;
  final List<String> themes;

  const TaskGenerationPrompt({
    required this.category,
    required this.difficulty,
    required this.taskType,
    required this.playerCount,
    this.availableItems = const [],
    this.location = 'indoor',
    this.timeLimit = const Duration(minutes: 10),
    this.themes = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category.name,
      'difficulty': difficulty.name,
      'taskType': taskType.name,
      'playerCount': playerCount,
      'availableItems': availableItems,
      'location': location,
      'timeLimit': timeLimit.inMinutes,
      'themes': themes,
    };
  }

  String toPromptString() {
    final buffer = StringBuffer();
    buffer.writeln('Generate a ${difficulty.name} ${category.name} task for ${playerCount} player(s).');
    buffer.writeln('Task type: ${taskType.name}');
    buffer.writeln('Location: $location');
    buffer.writeln('Time limit: ${timeLimit.inMinutes} minutes');
    
    if (availableItems.isNotEmpty) {
      buffer.writeln('Available items: ${availableItems.join(", ")}');
    }
    
    if (themes.isNotEmpty) {
      buffer.writeln('Themes: ${themes.join(", ")}');
    }
    
    buffer.writeln('\nRequirements:');
    buffer.writeln('- Create an entertaining and engaging task');
    buffer.writeln('- Ensure the task is appropriate for the difficulty level');
    buffer.writeln('- Make it fun and memorable');
    buffer.writeln('- Include clear completion criteria');
    
    return buffer.toString();
  }
}

abstract class AITaskService {
  Future<Task> generateTask(TaskGenerationPrompt prompt);
  Future<List<Task>> generateTaskBatch(TaskGenerationPrompt prompt, int count);
  Future<Task> enhanceTask(Task baseTask, List<String> enhancements);
  Future<List<TaskModifier>> suggestModifiers(Task task);
  Future<String> generateTaskDescription(String title, TaskCategory category);
}

class AITaskServiceImpl implements AITaskService {
  // In a real implementation, this would call Gemini API
  // For now, we'll use intelligent templates with randomization

  final Random _random = Random();
  
  @override
  Future<Task> generateTask(TaskGenerationPrompt prompt) async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate API call
    
    final taskTemplate = _selectTaskTemplate(prompt);
    final generatedTask = _customizeTask(taskTemplate, prompt);
    
    return generatedTask;
  }

  @override
  Future<List<Task>> generateTaskBatch(TaskGenerationPrompt prompt, int count) async {
    final tasks = <Task>[];
    
    for (int i = 0; i < count; i++) {
      final task = await generateTask(prompt);
      tasks.add(task.copyWith(
        id: 'ai_generated_${DateTime.now().millisecondsSinceEpoch}_$i',
      ));
      
      // Small delay between generations for realism
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    return tasks;
  }

  @override
  Future<Task> enhanceTask(Task baseTask, List<String> enhancements) async {
    await Future.delayed(const Duration(seconds: 1));
    
    String enhancedDescription = baseTask.description;
    String enhancedTitle = baseTask.title;
    
    for (final enhancement in enhancements) {
      switch (enhancement) {
        case 'add_humor':
          enhancedDescription = _addHumorToDescription(enhancedDescription);
          break;
        case 'increase_difficulty':
          enhancedDescription = _increaseDifficulty(enhancedDescription);
          break;
        case 'add_time_pressure':
          enhancedDescription += '\n\nTime pressure: Complete this as quickly as possible!';
          break;
        case 'add_creativity':
          enhancedDescription = _addCreativityElement(enhancedDescription);
          break;
        case 'make_collaborative':
          enhancedDescription = _makeCollaborative(enhancedDescription);
          break;
      }
    }
    
    return baseTask.copyWith(
      title: enhancedTitle,
      description: enhancedDescription,
    );
  }

  @override
  Future<List<TaskModifier>> suggestModifiers(Task task) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    final compatibleModifiers = TaskModifierGenerator.getCompatibleModifiers(task.taskType.name);
    final suggestedCount = 3 + _random.nextInt(3); // 3-5 suggestions
    
    compatibleModifiers.shuffle(_random);
    return compatibleModifiers.take(suggestedCount).toList();
  }

  @override
  Future<String> generateTaskDescription(String title, TaskCategory category) async {
    await Future.delayed(const Duration(seconds: 1));
    
    final templates = _getDescriptionTemplates(category);
    final template = templates[_random.nextInt(templates.length)];
    
    return template.replaceAll('{title}', title);
  }

  TaskTemplate _selectTaskTemplate(TaskGenerationPrompt prompt) {
    final templates = _getTaskTemplates(prompt.category, prompt.taskType);
    return templates[_random.nextInt(templates.length)];
  }

  Task _customizeTask(TaskTemplate template, TaskGenerationPrompt prompt) {
    String customizedTitle = template.title;
    String customizedDescription = template.description;
    
    // Customize based on player count
    if (prompt.playerCount > 1) {
      customizedDescription = _adaptForMultiplePlayers(customizedDescription, prompt.playerCount);
    }
    
    // Customize based on available items
    if (prompt.availableItems.isNotEmpty) {
      customizedDescription = _incorporateItems(customizedDescription, prompt.availableItems);
    }
    
    // Customize based on location
    customizedDescription = _adaptForLocation(customizedDescription, prompt.location);
    
    // Customize based on themes
    if (prompt.themes.isNotEmpty) {
      customizedDescription = _incorporateThemes(customizedDescription, prompt.themes);
    }
    
    return Task(
      id: 'ai_task_${DateTime.now().millisecondsSinceEpoch}',
      title: customizedTitle,
      description: customizedDescription,
      taskType: template.taskType,
      submissions: [],
    );
  }

  List<TaskTemplate> _getTaskTemplates(TaskCategory category, TaskType taskType) {
    return _taskTemplates
        .where((t) => t.category == category && t.taskType == taskType)
        .toList();
  }

  String _adaptForMultiplePlayers(String description, int playerCount) {
    if (description.contains('you')) {
      if (playerCount == 2) {
        description = description.replaceAll('you', 'you and your partner');
      } else {
        description = description.replaceAll('you', 'your team of $playerCount');
      }
    }
    return description;
  }

  String _incorporateItems(String description, List<String> items) {
    if (items.isNotEmpty) {
      final randomItems = items.take(3).join(', ');
      description += '\n\nUse these available items: $randomItems';
    }
    return description;
  }

  String _adaptForLocation(String description, String location) {
    if (location != 'indoor') {
      description = description.replaceAll('room', location);
      description = description.replaceAll('inside', location);
    }
    return description;
  }

  String _incorporateThemes(String description, List<String> themes) {
    if (themes.isNotEmpty) {
      final theme = themes[_random.nextInt(themes.length)];
      description += '\n\nTheme: Incorporate elements of "$theme" into your task.';
    }
    return description;
  }

  String _addHumorToDescription(String description) {
    final humorAdditions = [
      'Make it as ridiculous as possible!',
      'Add funny sound effects throughout.',
      'Pretend you\'re a nature documentary narrator.',
      'Do it while speaking in rhymes.',
      'Act like you\'re a robot the entire time.',
    ];
    
    return '$description\n\nHumor twist: ${humorAdditions[_random.nextInt(humorAdditions.length)]}';
  }

  String _increaseDifficulty(String description) {
    final difficultyAdditions = [
      'Complete this while balancing on one foot.',
      'Do this with your eyes closed for extra difficulty.',
      'Add an additional challenge of your choice.',
      'Complete this in half the normal time.',
      'Do this while reciting the alphabet backwards.',
    ];
    
    return '$description\n\nExtra challenge: ${difficultyAdditions[_random.nextInt(difficultyAdditions.length)]}';
  }

  String _addCreativityElement(String description) {
    final creativityAdditions = [
      'Make it artistic and visually appealing.',
      'Create a story to go along with your task.',
      'Add your own creative twist to make it unique.',
      'Incorporate music or rhythm into your approach.',
      'Design it like a performance piece.',
    ];
    
    return '$description\n\nCreative element: ${creativityAdditions[_random.nextInt(creativityAdditions.length)]}';
  }

  String _makeCollaborative(String description) {
    final collaborativeAdditions = [
      'Work together and communicate throughout.',
      'Take turns leading different parts.',
      'Each person adds their own contribution.',
      'Coordinate your movements and timing.',
      'Create a team cheer to celebrate completion.',
    ];
    
    return '$description\n\nTeamwork: ${collaborativeAdditions[_random.nextInt(collaborativeAdditions.length)]}';
  }

  List<String> _getDescriptionTemplates(TaskCategory category) {
    switch (category) {
      case TaskCategory.physical:
        return [
          'A dynamic physical challenge that will get your heart pumping and test your coordination.',
          'An energetic activity that combines movement with skill and creativity.',
          'A fun physical task that challenges your balance, speed, or agility.',
        ];
      case TaskCategory.creative:
        return [
          'An artistic challenge that lets your imagination run wild and showcases your creativity.',
          'A creative task that combines artistry with originality and personal expression.',
          'An imaginative activity that challenges you to think outside the box.',
        ];
      case TaskCategory.mental:
        return [
          'A brain-teasing puzzle that will challenge your logic and problem-solving skills.',
          'A mental challenge that tests your memory, reasoning, and quick thinking.',
          'A clever puzzle that requires strategy, observation, and mental agility.',
        ];
      default:
        return [
          'An entertaining challenge that combines skill, creativity, and fun.',
          'A unique task that will test your abilities in unexpected ways.',
          'A delightful activity that brings out your competitive and creative spirit.',
        ];
    }
  }

  static final List<TaskTemplate> _taskTemplates = [
    // Physical Video Tasks
    TaskTemplate(
      title: 'Dance Battle Royale',
      description: 'Create and perform a 60-second dance routine incorporating at least 5 different dance styles.',
      category: TaskCategory.physical,
      taskType: TaskType.video,
    ),
    TaskTemplate(
      title: 'Sock Puppet Theater',
      description: 'Using only socks, create puppets and perform a 2-minute comedy show with at least 3 characters.',
      category: TaskCategory.creative,
      taskType: TaskType.video,
    ),
    TaskTemplate(
      title: 'Kitchen Percussion Orchestra',
      description: 'Create a musical performance using only kitchen utensils and containers. Perform a recognizable song.',
      category: TaskCategory.creative,
      taskType: TaskType.video,
    ),
    
    // Puzzle Tasks
    TaskTemplate(
      title: 'Word Association Chain',
      description: 'Create a chain of 20 words where each word relates to the previous one. The chain must loop back to the first word.',
      category: TaskCategory.mental,
      taskType: TaskType.puzzle,
    ),
    TaskTemplate(
      title: 'Household Item Riddles',
      description: 'Create 5 riddles about common household items. Each riddle must have exactly 4 clues.',
      category: TaskCategory.mental,
      taskType: TaskType.puzzle,
    ),
    
    // Social Tasks
    TaskTemplate(
      title: 'Compliment Competition',
      description: 'Give each other player a unique, creative compliment that relates to a specific color.',
      category: TaskCategory.social,
      taskType: TaskType.video,
    ),
    
    // Food Tasks
    TaskTemplate(
      title: 'Blindfolded Taste Test',
      description: 'Identify 5 different foods while blindfolded, describing their taste using only emotion words.',
      category: TaskCategory.food,
      taskType: TaskType.video,
    ),
    
    // Silly Tasks
    TaskTemplate(
      title: 'Pet Impersonation Extravaganza',
      description: 'Impersonate 5 different pets for 30 seconds each, including their sounds and movements.',
      category: TaskCategory.silly,
      taskType: TaskType.video,
    ),
  ];
}

class TaskTemplate {
  final String title;
  final String description;
  final TaskCategory category;
  final TaskType taskType;

  const TaskTemplate({
    required this.title,
    required this.description,
    required this.category,
    required this.taskType,
  });
}

// Mock implementation for testing
class MockAITaskService implements AITaskService {
  final Random _random = Random();

  @override
  Future<Task> generateTask(TaskGenerationPrompt prompt) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    final mockTasks = [
      Task(
        id: 'mock_ai_task_1',
        title: 'AI Generated Dance Challenge',
        description: 'Create a dance that tells the story of your morning routine, complete with exaggerated movements for brushing teeth, making coffee, and getting dressed.',
        taskType: prompt.taskType,
        submissions: [],
      ),
      Task(
        id: 'mock_ai_task_2',
        title: 'Creative Problem Solving',
        description: 'Build the tallest structure possible using only items that are currently visible from where you\'re sitting. You have 5 minutes.',
        taskType: prompt.taskType,
        submissions: [],
      ),
      Task(
        id: 'mock_ai_task_3',
        title: 'Storytelling Symphony',
        description: 'Tell a 2-minute story where every sentence must start with the next letter of the alphabet. Start with A and see how far you get!',
        taskType: prompt.taskType,
        submissions: [],
      ),
    ];
    
    return mockTasks[_random.nextInt(mockTasks.length)];
  }

  @override
  Future<List<Task>> generateTaskBatch(TaskGenerationPrompt prompt, int count) async {
    final tasks = <Task>[];
    for (int i = 0; i < count; i++) {
      final task = await generateTask(prompt);
      tasks.add(task.copyWith(id: 'mock_batch_${i}_${DateTime.now().millisecondsSinceEpoch}'));
    }
    return tasks;
  }

  @override
  Future<Task> enhanceTask(Task baseTask, List<String> enhancements) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return baseTask.copyWith(
      description: '${baseTask.description}\n\nAI Enhancement: This task has been enhanced with: ${enhancements.join(", ")}',
    );
  }

  @override
  Future<List<TaskModifier>> suggestModifiers(Task task) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return TaskModifierGenerator.generateMultiple(3);
  }

  @override
  Future<String> generateTaskDescription(String title, TaskCategory category) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return 'AI generated description for "$title" in the ${category.name} category. This task combines creativity with skill and is designed to be entertaining and memorable.';
  }
}