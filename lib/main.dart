import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/theme/app_theme.dart';
import 'core/di/service_locator.dart';
import 'features/app/presentation/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize service locator with mock services for development
  await ServiceLocator.init(useMockServices: true);
  
  runApp(const TaskmasterApp());
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