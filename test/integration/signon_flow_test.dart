import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskmaster_app/core/di/service_locator.dart';
import 'package:taskmaster_app/features/app/presentation/app.dart';

/// Drives the real app widgets (mock services) through the first-run flow a
/// new player actually sees: login screen -> guest sign-in -> home -> open the
/// public games gallery -> see discoverable games. This is the headless stand-in
/// for "does signing on feel like a working, fun game".
void main() {
  setUp(() => ServiceLocator.init(useMockServices: true));
  tearDown(() => sl.reset());

  testWidgets('guest sign-in reaches home and can discover public games',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Material(child: App())),
    );
    // Initial auth check resolves to the login screen.
    await tester.pumpAndSettle();

    expect(find.text('Continue as Guest'), findsOneWidget,
        reason: 'login screen should offer a guest path');

    // Sign in as a guest.
    await tester.tap(find.text('Continue as Guest'));
    await tester.pump(); // dispatch
    await tester.pump(const Duration(seconds: 1)); // mock auth delay
    await tester.pumpAndSettle();

    // We should now be on the home screen.
    expect(find.textContaining('Quick Play'), findsWidgets,
        reason: 'home should show the Quick Play hero');

    // Open the public games gallery via the Discover FAB.
    await tester.tap(find.byIcon(Icons.public));
    await tester.pumpAndSettle();

    expect(find.text('Discover Games'), findsOneWidget);
    // The mock seeds public template games — they should be listed.
    expect(find.text('Weekend Warriors'), findsOneWidget);
    expect(find.text('Play these tasks'), findsWidgets);
  });
}
