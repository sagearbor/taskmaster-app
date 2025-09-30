import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:taskmaster_app/core/models/game.dart';
import 'package:taskmaster_app/core/models/task.dart';
import 'package:taskmaster_app/core/models/player.dart';
import 'package:taskmaster_app/core/models/player_task_status.dart';
import 'package:taskmaster_app/core/models/game_settings.dart';
import 'package:taskmaster_app/features/games/data/datasources/mock_game_data_source.dart';
import 'package:taskmaster_app/features/games/data/repositories/game_repository_impl.dart';

/// Integration tests for async game flow
/// These tests validate the complete end-to-end flow of async gameplay
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockGameDataSource mockDataSource;
  late GameRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockGameDataSource();
    repository = GameRepositoryImpl(remoteDataSource: mockDataSource);
  });

  tearDown(() {
    mockDataSource.dispose();
  });

  group('Test 1: Full Game Flow', () {
    testWidgets(
      'should complete full async game flow: create → select → start → submit → judge → score → next',
      (WidgetTester tester) async {
        // Step 1: Create game
        final newGame = Game(
          id: 'integration_test_1',
          gameName: 'Integration Test Game',
          creatorId: 'test_creator',
          judgeId: 'test_judge',
          status: GameStatus.lobby,
          inviteCode: 'INT001',
          createdAt: DateTime.now(),
          mode: GameMode.async,
          settings: GameSettings.quickPlay(),
          currentTaskIndex: 0,
          players: [
            const Player(
              userId: 'test_creator',
              displayName: 'Creator',
              totalScore: 0,
            ),
            const Player(
              userId: 'test_judge',
              displayName: 'Judge',
              totalScore: 0,
            ),
            const Player(
              userId: 'test_player1',
              displayName: 'Player 1',
              totalScore: 0,
            ),
          ],
          tasks: [
            Task(
              id: 'task_1',
              title: 'Test Task 1',
              description: 'Complete this task',
              taskType: TaskType.video,
              submissions: const [],
              playerStatuses: const {},
            ),
            Task(
              id: 'task_2',
              title: 'Test Task 2',
              description: 'Complete this task too',
              taskType: TaskType.video,
              submissions: const [],
              playerStatuses: const {},
            ),
          ],
        );

        final gameId = await repository.createGame(newGame);
        expect(gameId, 'integration_test_1');

        // Step 2: Start game
        final startedGame = await repository.startGame(gameId);
        expect(startedGame.status, GameStatus.inProgress);
        expect(startedGame.currentTaskIndex, 0);
        expect(startedGame.currentTask, isNotNull);
        expect(startedGame.currentTask!.playerStatuses.isNotEmpty, true);

        // Step 3: Submit task (all players)
        final updatedGame1 = await repository.submitTask(
          gameId,
          0,
          'test_creator',
          'https://youtube.com/watch?v=test1',
        );
        expect(
          updatedGame1.tasks[0].hasPlayerSubmitted('test_creator'),
          true,
        );

        final updatedGame2 = await repository.submitTask(
          gameId,
          0,
          'test_player1',
          'https://youtube.com/watch?v=test2',
        );
        expect(
          updatedGame2.tasks[0].hasPlayerSubmitted('test_player1'),
          true,
        );

        // Step 4: Judge submissions
        final judgedGame1 = await repository.judgeSubmission(
          gameId,
          0,
          'test_creator',
          5,
        );
        expect(
          judgedGame1.tasks[0].getPlayerStatus('test_creator')?.score,
          5,
        );

        final judgedGame2 = await repository.judgeSubmission(
          gameId,
          0,
          'test_player1',
          4,
        );
        expect(
          judgedGame2.tasks[0].getPlayerStatus('test_player1')?.score,
          4,
        );

        // Step 5: Check scores updated
        expect(judgedGame2.getPlayerById('test_creator')?.totalScore, 5);
        expect(judgedGame2.getPlayerById('test_player1')?.totalScore, 4);

        // Step 6: Advance to next task
        final advancedGame = await repository.advanceToNextTask(gameId);
        expect(advancedGame.currentTaskIndex, 1);
        expect(advancedGame.currentTask!.id, 'task_2');
      },
    );
  });

  group('Test 2: Out-of-Order Submissions', () {
    testWidgets(
      'should handle submissions in any order (player 3 submits before player 1)',
      (WidgetTester tester) async {
        final game = Game(
          id: 'test_out_of_order',
          gameName: 'Out of Order Test',
          creatorId: 'player1',
          judgeId: 'judge',
          status: GameStatus.lobby,
          inviteCode: 'ORDER',
          createdAt: DateTime.now(),
          mode: GameMode.async,
          settings: GameSettings.quickPlay(),
          currentTaskIndex: 0,
          players: const [
            Player(userId: 'player1', displayName: 'Player 1', totalScore: 0),
            Player(userId: 'player2', displayName: 'Player 2', totalScore: 0),
            Player(userId: 'player3', displayName: 'Player 3', totalScore: 0),
            Player(userId: 'judge', displayName: 'Judge', totalScore: 0),
          ],
          tasks: [
            Task(
              id: 'task_order',
              title: 'Order Test Task',
              description: 'Test out-of-order submissions',
              taskType: TaskType.video,
              submissions: const [],
              playerStatuses: const {},
            ),
          ],
        );

        final gameId = await repository.createGame(game);
        await repository.startGame(gameId);

        // Player 3 submits first
        final afterPlayer3 = await repository.submitTask(
          gameId,
          0,
          'player3',
          'https://youtube.com/watch?v=p3',
        );
        expect(afterPlayer3.tasks[0].submittedCount, 1);

        // Player 1 submits second
        final afterPlayer1 = await repository.submitTask(
          gameId,
          0,
          'player1',
          'https://youtube.com/watch?v=p1',
        );
        expect(afterPlayer1.tasks[0].submittedCount, 2);

        // Player 2 submits last
        final afterPlayer2 = await repository.submitTask(
          gameId,
          0,
          'player2',
          'https://youtube.com/watch?v=p2',
        );
        expect(afterPlayer2.tasks[0].submittedCount, 3);

        // All players except judge should have submitted
        expect(afterPlayer2.tasks[0].allPlayersSubmitted, false);
        expect(afterPlayer2.tasks[0].hasPlayerSubmitted('player1'), true);
        expect(afterPlayer2.tasks[0].hasPlayerSubmitted('player2'), true);
        expect(afterPlayer2.tasks[0].hasPlayerSubmitted('player3'), true);
        expect(afterPlayer2.tasks[0].hasPlayerSubmitted('judge'), false);
      },
    );
  });

  group('Test 3: Partial Judging', () {
    testWidgets(
      'should allow judge to score before all players submit',
      (WidgetTester tester) async {
        final game = Game(
          id: 'test_partial_judge',
          gameName: 'Partial Judging Test',
          creatorId: 'player1',
          judgeId: 'judge',
          status: GameStatus.lobby,
          inviteCode: 'PARTIAL',
          createdAt: DateTime.now(),
          mode: GameMode.async,
          settings: GameSettings.quickPlay(),
          currentTaskIndex: 0,
          players: const [
            Player(userId: 'player1', displayName: 'Player 1', totalScore: 0),
            Player(userId: 'player2', displayName: 'Player 2', totalScore: 0),
            Player(userId: 'player3', displayName: 'Player 3', totalScore: 0),
            Player(userId: 'judge', displayName: 'Judge', totalScore: 0),
          ],
          tasks: [
            Task(
              id: 'task_partial',
              title: 'Partial Judge Task',
              description: 'Test partial judging',
              taskType: TaskType.video,
              submissions: const [],
              playerStatuses: const {},
            ),
          ],
        );

        final gameId = await repository.createGame(game);
        await repository.startGame(gameId);

        // Only 2 out of 3 players submit
        await repository.submitTask(
          gameId,
          0,
          'player1',
          'https://youtube.com/watch?v=p1',
        );
        await repository.submitTask(
          gameId,
          0,
          'player2',
          'https://youtube.com/watch?v=p2',
        );
        // player3 doesn't submit

        // Judge can still score the submitted ones
        final judgedGame1 = await repository.judgeSubmission(
          gameId,
          0,
          'player1',
          5,
        );
        expect(judgedGame1.tasks[0].judgedCount, 1);

        final judgedGame2 = await repository.judgeSubmission(
          gameId,
          0,
          'player2',
          4,
        );
        expect(judgedGame2.tasks[0].judgedCount, 2);

        // Task is not fully judged yet (player3 hasn't submitted)
        expect(judgedGame2.tasks[0].allPlayersJudged, false);

        // But player1 and player2 have scores
        expect(judgedGame2.getPlayerById('player1')?.totalScore, 5);
        expect(judgedGame2.getPlayerById('player2')?.totalScore, 4);
        expect(judgedGame2.getPlayerById('player3')?.totalScore, 0);
      },
    );
  });

  group('Test 4: Skip Task Functionality', () {
    testWidgets(
      'should allow players to skip tasks when enabled',
      (WidgetTester tester) async {
        final game = Game(
          id: 'test_skip',
          gameName: 'Skip Test',
          creatorId: 'player1',
          judgeId: 'judge',
          status: GameStatus.lobby,
          inviteCode: 'SKIP',
          createdAt: DateTime.now(),
          mode: GameMode.async,
          settings: GameSettings(
            taskDeadlineHours: 24,
            autoAdvance: true,
            allowSkips: true,
            maxPlayers: 10,
          ),
          currentTaskIndex: 0,
          players: const [
            Player(userId: 'player1', displayName: 'Player 1', totalScore: 0),
            Player(userId: 'player2', displayName: 'Player 2', totalScore: 0),
            Player(userId: 'judge', displayName: 'Judge', totalScore: 0),
          ],
          tasks: [
            Task(
              id: 'task_skip',
              title: 'Skippable Task',
              description: 'Test skip functionality',
              taskType: TaskType.video,
              submissions: const [],
              playerStatuses: const {},
            ),
          ],
        );

        final gameId = await repository.createGame(game);
        await repository.startGame(gameId);

        // Player 1 submits normally
        await repository.submitTask(
          gameId,
          0,
          'player1',
          'https://youtube.com/watch?v=p1',
        );

        // Player 2 skips the task
        final skippedGame = await repository.skipTask(gameId, 0, 'player2');

        expect(
          skippedGame.tasks[0].getPlayerStatus('player2')?.state,
          TaskPlayerState.skipped,
        );
        expect(skippedGame.tasks[0].hasPlayerSubmitted('player2'), false);

        // Judge submissions - player2 gets 0 points for skip
        await repository.judgeSubmission(gameId, 0, 'player1', 5);

        final finalGame = await repository.getGame(gameId);
        expect(finalGame.getPlayerById('player1')?.totalScore, 5);
        expect(finalGame.getPlayerById('player2')?.totalScore, 0);
      },
    );
  });

  group('Test 5: Game Completion', () {
    testWidgets(
      'should complete game when all tasks are done',
      (WidgetTester tester) async {
        final game = Game(
          id: 'test_complete',
          gameName: 'Completion Test',
          creatorId: 'player1',
          judgeId: 'judge',
          status: GameStatus.lobby,
          inviteCode: 'COMPLETE',
          createdAt: DateTime.now(),
          mode: GameMode.async,
          settings: GameSettings.quickPlay(),
          currentTaskIndex: 0,
          players: const [
            Player(userId: 'player1', displayName: 'Player 1', totalScore: 0),
            Player(userId: 'player2', displayName: 'Player 2', totalScore: 0),
            Player(userId: 'judge', displayName: 'Judge', totalScore: 0),
          ],
          tasks: [
            Task(
              id: 'task_comp_1',
              title: 'Task 1',
              description: 'First task',
              taskType: TaskType.video,
              submissions: const [],
              playerStatuses: const {},
            ),
            Task(
              id: 'task_comp_2',
              title: 'Task 2',
              description: 'Second task',
              taskType: TaskType.video,
              submissions: const [],
              playerStatuses: const {},
            ),
          ],
        );

        final gameId = await repository.createGame(game);
        await repository.startGame(gameId);

        // Complete Task 1
        await repository.submitTask(
          gameId,
          0,
          'player1',
          'https://youtube.com/watch?v=p1t1',
        );
        await repository.submitTask(
          gameId,
          0,
          'player2',
          'https://youtube.com/watch?v=p2t1',
        );
        await repository.judgeSubmission(gameId, 0, 'player1', 5);
        await repository.judgeSubmission(gameId, 0, 'player2', 4);

        final afterTask1 = await repository.advanceToNextTask(gameId);
        expect(afterTask1.currentTaskIndex, 1);

        // Complete Task 2
        await repository.submitTask(
          gameId,
          1,
          'player1',
          'https://youtube.com/watch?v=p1t2',
        );
        await repository.submitTask(
          gameId,
          1,
          'player2',
          'https://youtube.com/watch?v=p2t2',
        );
        await repository.judgeSubmission(gameId, 1, 'player1', 4);
        await repository.judgeSubmission(gameId, 1, 'player2', 5);

        // Complete the game
        final completedGame = await repository.completeGame(gameId);
        expect(completedGame.status, GameStatus.completed);
        expect(completedGame.allTasksCompleted, true);

        // Check final scores
        expect(completedGame.getPlayerById('player1')?.totalScore, 9);
        expect(completedGame.getPlayerById('player2')?.totalScore, 9);
      },
    );
  });

  group('Test 6: Video Privacy Feature', () {
    testWidgets(
      'should enforce video privacy: players can only view videos after submitting',
      (WidgetTester tester) async {
        final game = Game(
          id: 'test_privacy',
          gameName: 'Privacy Test',
          creatorId: 'player1',
          judgeId: 'judge',
          status: GameStatus.lobby,
          inviteCode: 'PRIVACY',
          createdAt: DateTime.now(),
          mode: GameMode.async,
          settings: GameSettings.quickPlay(),
          currentTaskIndex: 0,
          players: const [
            Player(userId: 'player1', displayName: 'Player 1', totalScore: 0),
            Player(userId: 'player2', displayName: 'Player 2', totalScore: 0),
            Player(userId: 'player3', displayName: 'Player 3', totalScore: 0),
            Player(userId: 'judge', displayName: 'Judge', totalScore: 0),
          ],
          tasks: [
            Task(
              id: 'task_privacy',
              title: 'Privacy Task',
              description: 'Test video privacy',
              taskType: TaskType.video,
              submissions: const [],
              playerStatuses: const {},
            ),
          ],
        );

        final gameId = await repository.createGame(game);
        final startedGame = await repository.startGame(gameId);

        // Initially, no one can view videos
        expect(
          startedGame.tasks[0].canPlayerViewVideos('player1'),
          false,
        );
        expect(
          startedGame.tasks[0].canPlayerViewVideos('player2'),
          false,
        );
        expect(
          startedGame.tasks[0].canPlayerViewVideos('player3'),
          false,
        );

        // Player 1 submits
        final afterP1 = await repository.submitTask(
          gameId,
          0,
          'player1',
          'https://youtube.com/watch?v=p1',
        );

        // Player 1 can now view videos, others cannot
        expect(afterP1.tasks[0].canPlayerViewVideos('player1'), true);
        expect(afterP1.tasks[0].canPlayerViewVideos('player2'), false);
        expect(afterP1.tasks[0].canPlayerViewVideos('player3'), false);

        // Player 2 submits
        final afterP2 = await repository.submitTask(
          gameId,
          0,
          'player2',
          'https://youtube.com/watch?v=p2',
        );

        // Both Player 1 and 2 can view, Player 3 cannot
        expect(afterP2.tasks[0].canPlayerViewVideos('player1'), true);
        expect(afterP2.tasks[0].canPlayerViewVideos('player2'), true);
        expect(afterP2.tasks[0].canPlayerViewVideos('player3'), false);

        // Judge should be able to view all videos (regardless of submission)
        expect(afterP2.tasks[0].canPlayerViewVideos('judge'), true);

        // Player 3 skips
        final afterP3 = await repository.skipTask(gameId, 0, 'player3');

        // Player 3 can now view after skipping
        expect(afterP3.tasks[0].canPlayerViewVideos('player3'), true);
      },
    );
  });

  group('Test 7: Edge Cases', () {
    testWidgets(
      'should handle edge case: cannot start game without players',
      (WidgetTester tester) async {
        final game = Game(
          id: 'test_no_players',
          gameName: 'No Players Test',
          creatorId: 'creator',
          judgeId: 'judge',
          status: GameStatus.lobby,
          inviteCode: 'NOPLYR',
          createdAt: DateTime.now(),
          mode: GameMode.async,
          settings: GameSettings.quickPlay(),
          currentTaskIndex: 0,
          players: const [
            Player(userId: 'creator', displayName: 'Creator', totalScore: 0),
          ],
          tasks: [
            Task(
              id: 'task_1',
              title: 'Task 1',
              description: 'Test',
              taskType: TaskType.video,
              submissions: const [],
              playerStatuses: const {},
            ),
          ],
        );

        final gameId = await repository.createGame(game);

        // Should not be able to start with only 1 player
        expect(
          () => repository.startGame(gameId),
          throwsException,
        );
      },
    );

    testWidgets(
      'should handle edge case: cannot start game without tasks',
      (WidgetTester tester) async {
        final game = Game(
          id: 'test_no_tasks',
          gameName: 'No Tasks Test',
          creatorId: 'creator',
          judgeId: 'judge',
          status: GameStatus.lobby,
          inviteCode: 'NOTASK',
          createdAt: DateTime.now(),
          mode: GameMode.async,
          settings: GameSettings.quickPlay(),
          currentTaskIndex: 0,
          players: const [
            Player(userId: 'creator', displayName: 'Creator', totalScore: 0),
            Player(userId: 'player1', displayName: 'Player 1', totalScore: 0),
          ],
          tasks: const [],
        );

        final gameId = await repository.createGame(game);

        // Should not be able to start without tasks
        expect(
          () => repository.startGame(gameId),
          throwsException,
        );
      },
    );

    testWidgets(
      'should handle double submission (idempotent)',
      (WidgetTester tester) async {
        final game = Game(
          id: 'test_double_submit',
          gameName: 'Double Submit Test',
          creatorId: 'player1',
          judgeId: 'judge',
          status: GameStatus.lobby,
          inviteCode: 'DOUBLE',
          createdAt: DateTime.now(),
          mode: GameMode.async,
          settings: GameSettings.quickPlay(),
          currentTaskIndex: 0,
          players: const [
            Player(userId: 'player1', displayName: 'Player 1', totalScore: 0),
            Player(userId: 'judge', displayName: 'Judge', totalScore: 0),
          ],
          tasks: [
            Task(
              id: 'task_double',
              title: 'Double Task',
              description: 'Test double submission',
              taskType: TaskType.video,
              submissions: const [],
              playerStatuses: const {},
            ),
          ],
        );

        final gameId = await repository.createGame(game);
        await repository.startGame(gameId);

        // First submission
        final after1 = await repository.submitTask(
          gameId,
          0,
          'player1',
          'https://youtube.com/watch?v=first',
        );
        expect(after1.tasks[0].submittedCount, 1);

        // Second submission (should update, not duplicate)
        final after2 = await repository.submitTask(
          gameId,
          0,
          'player1',
          'https://youtube.com/watch?v=second',
        );
        expect(after2.tasks[0].submittedCount, 1);
        expect(
          after2.tasks[0].getPlayerStatus('player1')?.videoUrl,
          'https://youtube.com/watch?v=second',
        );
      },
    );
  });
}