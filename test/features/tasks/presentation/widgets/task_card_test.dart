import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskmaster_app/core/models/task.dart';
import 'package:taskmaster_app/features/tasks/presentation/widgets/task_card.dart';

void main() {
  group('TaskCard', () {
    final testVideoTask = Task(
      id: 'test_video_1',
      title: 'Test Video Task',
      description: 'This is a test video task description that should be displayed.',
      taskType: TaskType.video,
      submissions: const [],
      durationSeconds: 300, // 5 minutes
    );

    final testPuzzleTask = Task(
      id: 'test_puzzle_1',
      title: 'Test Puzzle Task',
      description: 'This is a test puzzle task description.',
      taskType: TaskType.puzzle,
      submissions: const [],
      durationSeconds: 120, // 2 minutes
    );

    final testTaskWithoutDuration = Task(
      id: 'test_no_duration',
      title: 'Task Without Duration',
      description: 'This task has no duration specified.',
      taskType: TaskType.video,
      submissions: const [],
    );

    testWidgets('should display task title', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(task: testVideoTask),
          ),
        ),
      );

      // Assert
      expect(find.text('Test Video Task'), findsOneWidget);
    });

    testWidgets('should display task description', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(task: testVideoTask),
          ),
        ),
      );

      // Assert
      expect(find.textContaining('This is a test video task'), findsOneWidget);
    });

    testWidgets('should display video icon for video tasks', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(task: testVideoTask),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.videocam), findsOneWidget);
    });

    testWidgets('should display puzzle icon for puzzle tasks', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(task: testPuzzleTask),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.extension), findsOneWidget);
    });

    testWidgets('should display VIDEO badge for video tasks', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(task: testVideoTask),
          ),
        ),
      );

      // Assert
      expect(find.text('VIDEO'), findsOneWidget);
    });

    testWidgets('should display PUZZLE badge for puzzle tasks', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(task: testPuzzleTask),
          ),
        ),
      );

      // Assert
      expect(find.text('PUZZLE'), findsOneWidget);
    });

    testWidgets('should display duration when available', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(task: testVideoTask),
          ),
        ),
      );

      // Assert
      expect(find.text('5m'), findsOneWidget);
      expect(find.byIcon(Icons.timer), findsOneWidget);
    });

    testWidgets('should format duration correctly for seconds only', (tester) async {
      // Arrange
      final task = Task(
        id: 'test',
        title: 'Test',
        description: 'Test',
        taskType: TaskType.video,
        submissions: const [],
        durationSeconds: 45,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(task: task),
          ),
        ),
      );

      // Assert
      expect(find.text('45s'), findsOneWidget);
    });

    testWidgets('should format duration correctly for minutes and seconds', (tester) async {
      // Arrange
      final task = Task(
        id: 'test',
        title: 'Test',
        description: 'Test',
        taskType: TaskType.video,
        submissions: const [],
        durationSeconds: 125, // 2m 5s
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(task: task),
          ),
        ),
      );

      // Assert
      expect(find.text('2m 5s'), findsOneWidget);
    });

    testWidgets('should not display duration when not available', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(task: testTaskWithoutDuration),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.timer), findsNothing);
    });

    testWidgets('should show check icon when selected', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(
              task: testVideoTask,
              isSelected: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should not show check icon when not selected', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(
              task: testVideoTask,
              isSelected: false,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('should have elevated appearance when selected', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(
              task: testVideoTask,
              isSelected: true,
            ),
          ),
        ),
      );

      // Assert
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 4);
    });

    testWidgets('should have normal appearance when not selected', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(
              task: testVideoTask,
              isSelected: false,
            ),
          ),
        ),
      );

      // Assert
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 1);
    });

    testWidgets('should call onTap when tapped', (tester) async {
      // Arrange
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(
              task: testVideoTask,
              onTap: () => wasTapped = true,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(TaskCard));
      await tester.pump();

      // Assert
      expect(wasTapped, isTrue);
    });

    testWidgets('should call onLongPress when long pressed', (tester) async {
      // Arrange
      bool wasLongPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(
              task: testVideoTask,
              onLongPress: () => wasLongPressed = true,
            ),
          ),
        ),
      );

      // Act
      await tester.longPress(find.byType(TaskCard));
      await tester.pump();

      // Assert
      expect(wasLongPressed, isTrue);
    });

    testWidgets('should truncate long titles with ellipsis', (tester) async {
      // Arrange
      final longTitleTask = Task(
        id: 'long_title',
        title: 'This is a very long task title that should be truncated with ellipsis because it exceeds the maximum allowed length',
        description: 'Description',
        taskType: TaskType.video,
        submissions: const [],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: TaskCard(task: longTitleTask),
            ),
          ),
        ),
      );

      // Assert
      final titleText = tester.widget<Text>(
        find.textContaining('This is a very long'),
      );
      expect(titleText.maxLines, 2);
      expect(titleText.overflow, TextOverflow.ellipsis);
    });

    testWidgets('should truncate long descriptions with ellipsis', (tester) async {
      // Arrange
      final longDescTask = Task(
        id: 'long_desc',
        title: 'Test',
        description: 'This is a very long task description that should be truncated with ellipsis because it exceeds the maximum allowed length for the description field in the task card component',
        taskType: TaskType.video,
        submissions: const [],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: TaskCard(task: longDescTask),
            ),
          ),
        ),
      );

      // Assert
      final descText = tester.widget<Text>(
        find.textContaining('This is a very long'),
      );
      expect(descText.maxLines, 3);
      expect(descText.overflow, TextOverflow.ellipsis);
    });

    testWidgets('should render correctly without callbacks', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(task: testVideoTask),
          ),
        ),
      );

      // Assert - Should not throw
      expect(find.byType(TaskCard), findsOneWidget);
    });

    testWidgets('should display all required elements together', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(
              task: testVideoTask,
              isSelected: true,
            ),
          ),
        ),
      );

      // Assert - Verify all key elements are present
      expect(find.text('Test Video Task'), findsOneWidget);
      expect(find.textContaining('This is a test video task'), findsOneWidget);
      expect(find.byIcon(Icons.videocam), findsOneWidget);
      expect(find.text('VIDEO'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('5m'), findsOneWidget);
      expect(find.byIcon(Icons.timer), findsOneWidget);
    });
  });
}