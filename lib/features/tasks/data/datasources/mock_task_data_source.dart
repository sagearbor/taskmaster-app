import 'dart:async';

import 'task_remote_data_source.dart';

class MockTaskDataSource implements TaskRemoteDataSource {
  final List<Map<String, dynamic>> _communityTasks = [];

  MockTaskDataSource() {
    _initializeMockCommunityTasks();
  }

  void _initializeMockCommunityTasks() {
    final mockTasks = [
      {
        'id': 'community_1',
        'title': 'Recreate a famous painting with household items',
        'description': 'Choose any famous painting and recreate it using only items you can find around your house. Bonus points for creativity and accuracy.',
        'taskType': 'video',
        'puzzleAnswer': null,
        'submittedBy': 'user_123',
        'upvotes': 47,
        'createdAt': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      },
      {
        'id': 'community_2',
        'title': 'What has keys but no locks riddle',
        'description': 'I have keys but no locks. I have space but no room. You can enter but not go inside. What am I?',
        'taskType': 'puzzle',
        'puzzleAnswer': 'keyboard',
        'submittedBy': 'user_456',
        'upvotes': 23,
        'createdAt': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      },
      {
        'id': 'community_3',
        'title': 'Perform a magic trick',
        'description': 'Show us your best magic trick! It can be simple sleight of hand, a card trick, or even just making something disappear. Explain how impressed we should be.',
        'taskType': 'video',
        'puzzleAnswer': null,
        'submittedBy': 'user_789',
        'upvotes': 35,
        'createdAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        'id': 'community_4',
        'title': 'Count the triangles',
        'description': 'In a triangle divided into smaller triangles by drawing lines from each vertex to the opposite side, creating 6 smaller triangles, how many triangles can you count in total?',
        'taskType': 'puzzle',
        'puzzleAnswer': '13',
        'submittedBy': 'user_101',
        'upvotes': 15,
        'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'id': 'community_5',
        'title': 'Create a commercial for a mundane object',
        'description': 'Pick the most boring object you can find (like a paperclip, rubber band, or spoon) and create a 30-second commercial trying to sell it as the most amazing product ever.',
        'taskType': 'video',
        'puzzleAnswer': null,
        'submittedBy': 'user_202',
        'upvotes': 42,
        'createdAt': DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
      },
    ];

    _communityTasks.addAll(mockTasks);
  }

  @override
  Future<List<Map<String, dynamic>>> getCommunityTasks() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_communityTasks);
  }

  @override
  Future<String> createCommunityTask(Map<String, dynamic> taskData) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    _communityTasks.add(taskData);
    return taskData['id'] as String;
  }

  @override
  Future<void> upvoteTask(String taskId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final taskIndex = _communityTasks.indexWhere((task) => task['id'] == taskId);
    if (taskIndex != -1) {
      _communityTasks[taskIndex]['upvotes'] = 
          (_communityTasks[taskIndex]['upvotes'] as int) + 1;
    }
  }
}