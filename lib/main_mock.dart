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

import 'core/theme/app_theme.dart';
import 'core/di/service_locator.dart';
import 'core/config/environment.dart';
import 'core/error/error_handler.dart';
import 'core/cache/cache_manager.dart';
import 'core/utils/performance.dart' as perf;
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/screens/auth_wrapper.dart';

void main() async {
  await _initializeApp();
  
  runApp(
    ErrorBoundary(
      child: perf.PerformanceOverlay(
        enabled: AppConfig.isDevelopment,
        child: const TaskCasterApp(),
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

class TaskCasterApp extends StatelessWidget {
  const TaskCasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide AuthBloc ABOVE MaterialApp (matching lib/main.dart) so every
    // pushed route — Discover, game detail, etc. — can read it. Providing it
    // inside `home` instead leaves pushed routes without an AuthBloc ancestor.
    return BlocProvider(
      create: (context) => AuthBloc(
        authRepository: sl<AuthRepository>(),
      )..add(AuthCheckRequested()),
      child: MaterialApp(
        title: 'TaskCaster Party App',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
      ),
    );
  }
}