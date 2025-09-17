import 'package:cloud_firestore/cloud_firestore.dart';

import 'task_remote_data_source.dart';

class FirebaseTaskDataSource implements TaskRemoteDataSource {
  final FirebaseFirestore _firestore;

  FirebaseTaskDataSource({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Map<String, dynamic>>> getCommunityTasks() async {
    try {
      final querySnapshot = await _firestore
          .collection('community_tasks')
          .orderBy('upvotes', descending: true)
          .limit(100) // Limit to prevent excessive data usage
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get community tasks: $e');
    }
  }

  @override
  Future<String> createCommunityTask(Map<String, dynamic> taskData) async {
    try {
      taskData['createdAt'] = FieldValue.serverTimestamp();
      taskData['upvotes'] = 0;
      
      final docRef = await _firestore.collection('community_tasks').add(taskData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create community task: $e');
    }
  }

  @override
  Future<void> upvoteTask(String taskId) async {
    try {
      await _firestore.collection('community_tasks').doc(taskId).update({
        'upvotes': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to upvote task: $e');
    }
  }

  Future<void> downvoteTask(String taskId) async {
    try {
      await _firestore.collection('community_tasks').doc(taskId).update({
        'upvotes': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Failed to downvote task: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCommunityTasksByUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('community_tasks')
          .where('submittedBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get user community tasks: $e');
    }
  }

  Future<List<Map<String, dynamic>>> searchCommunityTasks(String query) async {
    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation that searches by title
      // For production, consider using Algolia or similar service
      final querySnapshot = await _firestore
          .collection('community_tasks')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: '$query\uf8ff')
          .orderBy('title')
          .limit(50)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to search community tasks: $e');
    }
  }

  Future<void> deleteCommunityTask(String taskId, String userId) async {
    try {
      // Verify the user owns this task
      final taskDoc = await _firestore.collection('community_tasks').doc(taskId).get();
      if (!taskDoc.exists) {
        throw Exception('Task not found');
      }

      final taskData = taskDoc.data()!;
      if (taskData['submittedBy'] != userId) {
        throw Exception('You can only delete your own tasks');
      }

      await _firestore.collection('community_tasks').doc(taskId).delete();
    } catch (e) {
      throw Exception('Failed to delete community task: $e');
    }
  }

  Future<void> updateCommunityTask(
    String taskId,
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      // Verify the user owns this task
      final taskDoc = await _firestore.collection('community_tasks').doc(taskId).get();
      if (!taskDoc.exists) {
        throw Exception('Task not found');
      }

      final taskData = taskDoc.data()!;
      if (taskData['submittedBy'] != userId) {
        throw Exception('You can only edit your own tasks');
      }

      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('community_tasks').doc(taskId).update(updates);
    } catch (e) {
      throw Exception('Failed to update community task: $e');
    }
  }

  Future<Map<String, dynamic>?> getCommunityTask(String taskId) async {
    try {
      final taskDoc = await _firestore.collection('community_tasks').doc(taskId).get();
      if (!taskDoc.exists) return null;

      final data = taskDoc.data()!;
      data['id'] = taskDoc.id;
      return data;
    } catch (e) {
      throw Exception('Failed to get community task: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getFeaturedTasks() async {
    try {
      final querySnapshot = await _firestore
          .collection('community_tasks')
          .where('upvotes', isGreaterThan: 10) // Featured threshold
          .orderBy('upvotes', descending: true)
          .limit(20)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get featured tasks: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTasksByType(String taskType) async {
    try {
      final querySnapshot = await _firestore
          .collection('community_tasks')
          .where('taskType', isEqualTo: taskType)
          .orderBy('upvotes', descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get tasks by type: $e');
    }
  }

  Future<void> reportTask(String taskId, String reason, String reportedBy) async {
    try {
      await _firestore.collection('task_reports').add({
        'taskId': taskId,
        'reason': reason,
        'reportedBy': reportedBy,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Failed to report task: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getCommunityTasksStream() {
    return _firestore
        .collection('community_tasks')
        .orderBy('upvotes', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
}