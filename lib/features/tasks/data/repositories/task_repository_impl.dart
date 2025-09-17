import 'package:uuid/uuid.dart';

import '../../../../core/models/community_task.dart';
import '../../../../core/models/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_data_source.dart';
import '../datasources/prebuilt_tasks_data.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource remoteDataSource;
  final Uuid _uuid = const Uuid();

  TaskRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<CommunityTask>> getCommunityTasks() async {
    final tasksData = await remoteDataSource.getCommunityTasks();
    return tasksData.map((data) => CommunityTask.fromMap(data)).toList();
  }

  @override
  Future<String> createCommunityTask(CommunityTask task) async {
    final taskData = task.copyWith(id: _uuid.v4()).toMap();
    return await remoteDataSource.createCommunityTask(taskData);
  }

  @override
  Future<void> upvoteTask(String taskId) async {
    await remoteDataSource.upvoteTask(taskId);
  }

  @override
  Future<List<Task>> getPrebuiltTasks() async {
    return PrebuiltTasksData.getAllTasks();
  }

  @override
  Future<List<Task>> getRandomTasks(int count) async {
    final allTasks = await getPrebuiltTasks();
    allTasks.shuffle();
    return allTasks.take(count).toList();
  }
}