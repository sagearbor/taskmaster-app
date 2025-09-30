import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskmaster_app/core/widgets/error_view.dart';

void main() {
  group('ErrorView', () {
    testWidgets('displays error message and details', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView(
              message: 'Test Error',
              details: 'Test details',
            ),
          ),
        ),
      );

      expect(find.text('Test Error'), findsOneWidget);
      expect(find.text('Test details'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry provided', (tester) async {
      bool retryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView(
              message: 'Test Error',
              onRetry: () => retryPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retryPressed, true);
    });

    testWidgets('hides retry button when onRetry not provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView(
              message: 'Test Error',
            ),
          ),
        ),
      );

      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('ErrorView.network shows network-specific message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView.network(),
          ),
        ),
      );

      expect(find.text('Connection error'), findsOneWidget);
      expect(find.text('Please check your internet connection and try again.'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets('ErrorView.empty shows empty state message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView.empty(entity: 'games'),
          ),
        ),
      );

      expect(find.text('No games found'), findsOneWidget);
      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('ErrorView.notFound shows not found message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView.notFound(entity: 'game'),
          ),
        ),
      );

      expect(find.text('game not found'), findsOneWidget);
      expect(find.text('The requested game could not be found.'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });
  });

  group('InlineError', () {
    testWidgets('displays inline error message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InlineError(
              message: 'Inline error message',
            ),
          ),
        ),
      );

      expect(find.text('Inline error message'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry provided', (tester) async {
      bool retryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InlineError(
              message: 'Error',
              onRetry: () => retryPressed = true,
            ),
          ),
        ),
      );

      final retryButton = find.byIcon(Icons.refresh);
      expect(retryButton, findsOneWidget);

      await tester.tap(retryButton);
      await tester.pump();

      expect(retryPressed, true);
    });
  });
}