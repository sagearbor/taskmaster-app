import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Navigation Flow Tests', () {
    testWidgets('Back button shows confirmation dialog when data entered', (tester) async {
      bool confirmationShown = false;
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return WillPopScope(
                onWillPop: () async {
                  if (controller.text.isNotEmpty) {
                    confirmationShown = true;
                    final shouldPop = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Discard changes?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Stay'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Leave'),
                          ),
                        ],
                      ),
                    );
                    return shouldPop ?? false;
                  }
                  return true;
                },
                child: Scaffold(
                  appBar: AppBar(title: const Text('Test Screen')),
                  body: Column(
                    children: [
                      TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'Enter text',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Enter text in the field
      await tester.enterText(find.byType(TextField), 'test data');
      await tester.pump();

      // Try to go back
      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle();

      // Verify confirmation was requested
      expect(confirmationShown, true);
      expect(find.text('Discard changes?'), findsOneWidget);

      // Test "Stay" button
      await tester.tap(find.text('Stay'));
      await tester.pumpAndSettle();

      // Should still be on the screen
      expect(find.text('Test Screen'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Back button allows navigation when no data entered', (tester) async {
      bool backAllowed = false;
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: WillPopScope(
            onWillPop: () async {
              if (controller.text.isEmpty) {
                backAllowed = true;
                return true;
              }
              return false;
            },
            child: Scaffold(
              appBar: AppBar(title: const Text('Test Screen')),
              body: TextField(controller: controller),
            ),
          ),
        ),
      );

      // Don't enter any text, just try to go back
      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pop();
      await tester.pump();

      // Should allow back navigation
      expect(backAllowed, true);
    });

    testWidgets('Error retry button triggers callback', (tester) async {
      bool retryTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Error occurred'),
                  ElevatedButton(
                    onPressed: () => retryTriggered = true,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Tap retry button
      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retryTriggered, true);
    });
  });
}