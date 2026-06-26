import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskcaster_app/core/di/service_locator.dart';
import 'package:taskcaster_app/core/theme/app_theme.dart';
import 'package:taskcaster_app/core/utils/performance.dart' as perf;
import 'package:taskcaster_app/features/app/presentation/app.dart';

// Probe: boot the app exactly how main_mock does — wrapped in the dev
// PerformanceOverlay — and surface any startup/layout exception.
void main() {
  setUp(() => ServiceLocator.init(useMockServices: true));
  tearDown(() => sl.reset());

  testWidgets('main_mock-style shell (PerformanceOverlay enabled) boots clean',
      (tester) async {
    await tester.pumpWidget(
      perf.PerformanceOverlay(
        enabled: true,
        child: MaterialApp(
          title: 'TaskCaster Party App',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const Material(child: App()),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}
