/// Entry point for running with mock services only (no Firebase required)
/// 
/// Use this to run the app without Firebase setup:
/// ```bash
/// flutter run -d chrome -t lib/main_mock.dart
/// ```

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/theme/app_theme.dart';
import 'core/di/service_locator.dart';
import 'core/config/environment.dart';
import 'core/error/error_handler.dart';
import 'core/cache/cache_manager.dart';
import 'core/utils/performance.dart' as perf;
import 'core/services/ad_service_simple.dart';
import 'features/app/presentation/app.dart';

void main() async {
  await _initializeApp();
  
  runApp(
    ErrorBoundary(
      child: perf.PerformanceOverlay(
        enabled: AppConfig.isDevelopment,
        child: const TaskmasterApp(),
      ),
    ),
  );
}

Future<void> _initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set environment to development
  AppConfig.setEnvironment(Environment.development);
  
  // Initialize error handling
  FlutterError.onError = (details) {
    ErrorHandler.handleError(
      details.exception,
      details.stack,
      context: 'Flutter Framework',
    );
  };
  
  // Initialize cache manager
  await CacheManager.instance;
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize service locator with MOCK services only
  await ServiceLocator.init(useMockServices: true);
}

class TaskmasterApp extends StatelessWidget {
  const TaskmasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taskmaster Party App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const Material(
        child: App(),
      ),
    );
  }
}