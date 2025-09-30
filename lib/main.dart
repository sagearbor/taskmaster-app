/// Main entry point for Taskmaster Party App
/// Run with: flutter run -d chrome

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'core/theme/app_theme.dart';
import 'core/di/service_locator.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize services with mocks (Firebase data sources not yet implemented)
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
      debugShowCheckedModeBanner: false,
      home: BlocProvider(
        create: (context) => AuthBloc(
          authRepository: sl<AuthRepository>(),
        )..add(AuthCheckRequested()),
        child: const AuthScreen(),
      ),
    );
  }
}

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is AuthAuthenticated) {
          return const HomeScreen();
        }

        // Default to login screen
        return const LoginScreen();
      },
    );
  }
}