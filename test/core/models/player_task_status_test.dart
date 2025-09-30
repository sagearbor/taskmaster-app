import 'package:flutter_test/flutter_test.dart';
import 'package:taskmaster_app/core/models/player_task_status.dart';

void main() {
  group('PlayerTaskStatus', () {
    test('creates with required fields', () {
      final status = PlayerTaskStatus(
        playerId: 'user1',
        state: TaskPlayerState.not_started,
      );

      expect(status.playerId, 'user1');
      expect(status.state, TaskPlayerState.not_started);
      expect(status.hasSubmitted, false);
      expect(status.isJudged, false);
      expect(status.canViewVideos, false);
    });

    test('toMap and fromMap work correctly', () {
      final original = PlayerTaskStatus(
        playerId: 'user1',
        state: TaskPlayerState.submitted,
        startedAt: DateTime(2025, 1, 1, 10, 0),
        submittedAt: DateTime(2025, 1, 1, 10, 30),
        submissionUrl: 'https://youtube.com/watch?v=test',
        score: 4,
        scoredAt: DateTime(2025, 1, 1, 11, 0),
      );

      final map = original.toMap();
      final restored = PlayerTaskStatus.fromMap(map);

      expect(restored.playerId, original.playerId);
      expect(restored.state, original.state);
      expect(restored.startedAt, original.startedAt);
      expect(restored.submittedAt, original.submittedAt);
      expect(restored.submissionUrl, original.submissionUrl);
      expect(restored.score, original.score);
      expect(restored.scoredAt, original.scoredAt);
    });

    test('hasSubmitted returns true for submitted state', () {
      final status = PlayerTaskStatus(
        playerId: 'user1',
        state: TaskPlayerState.submitted,
      );

      expect(status.hasSubmitted, true);
      expect(status.canViewVideos, true); // Privacy: can view after submit
    });

    test('hasSubmitted returns true for judged state', () {
      final status = PlayerTaskStatus(
        playerId: 'user1',
        state: TaskPlayerState.judged,
        score: 5,
      );

      expect(status.hasSubmitted, true);
      expect(status.isJudged, true);
      expect(status.canViewVideos, true);
    });

    test('canViewVideos returns false before submission', () {
      final status = PlayerTaskStatus(
        playerId: 'user1',
        state: TaskPlayerState.in_progress,
      );

      expect(status.canViewVideos, false); // Privacy: can't view until submit
    });

    test('copyWith works correctly', () {
      final original = PlayerTaskStatus(
        playerId: 'user1',
        state: TaskPlayerState.not_started,
      );

      final updated = original.copyWith(
        state: TaskPlayerState.submitted,
        submissionUrl: 'https://youtube.com/test',
      );

      expect(updated.playerId, 'user1'); // unchanged
      expect(updated.state, TaskPlayerState.submitted); // changed
      expect(updated.submissionUrl, 'https://youtube.com/test'); // changed
    });
  });
}