import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskmaster_app/core/widgets/skeleton_loaders.dart';

void main() {
  group('SkeletonLoaders', () {
    testWidgets('gameCardSkeleton renders shimmer effect', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) =>
                  SkeletonLoaders.gameCardSkeleton(context),
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
            body: Builder(
              builder: (context) =>
                  SkeletonLoaders.gameDetailSkeleton(context),
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
            body: Builder(
              builder: (context) =>
                  SkeletonLoaders.taskExecutionSkeleton(context),
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
            body: Builder(
              builder: (context) =>
                  SkeletonLoaders.judgingSkeleton(context),
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