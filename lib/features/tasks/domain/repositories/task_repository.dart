import '../../../../core/models/community_task.dart';
import '../../../../core/models/task.dart';

abstract class TaskRepository {
  Future<List<CommunityTask>> getCommunityTasks();
  Future<String> createCommunityTask(CommunityTask task);
  Future<void> upvoteTask(String taskId);
  Future<List<Task>> getPrebuiltTasks();
  Future<List<Task>> getRandomTasks(int count);
}