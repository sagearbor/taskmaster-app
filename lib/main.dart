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
import 'core/utils/performance.dart';
import 'core/services/ad_service_simple.dart';
import 'features/app/presentation/app.dart';

void main() async {
  await _initializeApp();
  
  runApp(
    ErrorBoundary(
      child: PerformanceOverlay(
        enabled: AppConfig.isDevelopment,
        child: const TaskmasterApp(),
      ),
    ),
  );
}

Future<void> _initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set environment based on build mode
  AppConfig.setEnvironment(
    kDebugMode ? Environment.development : Environment.production,
  );
  
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
  
  // Initialize service locator
  await ServiceLocator.init(
    useMockServices: AppConfig.isDevelopment || BuildConfig.useMockServices,
  );
  
  // Initialize ads service if enabled
  if (AppConfig.enableAds) {
    final adService = sl<AdService>();
    await adService.initialize();
  }
}

class TaskmasterApp extends StatelessWidget {
  const TaskmasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taskmaster Party App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const App(),
      debugShowCheckedModeBanner: false,
    );
  }
}