abstract class TaskRemoteDataSource {
  Future<List<Map<String, dynamic>>> getCommunityTasks();
  Future<String> createCommunityTask(Map<String, dynamic> taskData);
  Future<void> upvoteTask(String taskId);
}