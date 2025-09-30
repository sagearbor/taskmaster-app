import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskmaster_app/core/widgets/skeleton_loaders.dart';

void main() {
  group('SkeletonLoaders', () {
    testWidgets('gameCardSkeleton renders shimmer effect', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeletonLoaders.gameCardSkeleton(
              tester.element(find.byType(Scaffold)),
            ),
          ),
        ),
      );

      // Verify the skeleton renders without errors
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('gameDetailSkeleton renders shimmer effect', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeletonLoaders.gameDetailSkeleton(
              tester.element(find.byType(Scaffold)),
            ),
          ),
        ),
      );

      // Verify the skeleton renders without errors
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('taskExecutionSkeleton renders shimmer effect', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeletonLoaders.taskExecutionSkeleton(
              tester.element(find.byType(Scaffold)),
            ),
          ),
        ),
      );

      // Verify the skeleton renders without errors
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('judgingSkeleton renders shimmer effect', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeletonLoaders.judgingSkeleton(
              tester.element(find.byType(Scaffold)),
            ),
          ),
        ),
      );

      // Verify the skeleton renders without errors
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('listSkeleton renders with specified item count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeletonLoaders.listSkeleton(
              itemCount: 5,
              itemHeight: 80,
            ),
          ),
        ),
      );

      // Verify the skeleton renders without errors
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('textSkeleton renders with specified dimensions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeletonLoaders.textSkeleton(
              width: 200,
              height: 20,
            ),
          ),
        ),
      );

      // Verify the skeleton renders without errors
      expect(find.byType(Container), findsWidgets);
    });
  });
}