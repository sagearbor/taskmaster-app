import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_form.dart';
import 'register_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero header
              Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.heroGradient,
                  borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(36)),
                ),
                padding: EdgeInsets.fromLTRB(
                    24, MediaQuery.of(context).padding.top + 56, 24, 44),
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.25), width: 1.5),
                      ),
                      child: const Icon(Icons.star_rounded,
                          size: 52, color: AppTheme.goldBright),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'TaskCaster Party',
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Compete in creative challenges with friends',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.82)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                AuthForm(
                  title: 'Sign In',
                  buttonText: 'Sign In',
                  onSubmit: (email, password, displayName) {
                    context.read<AuthBloc>().add(
                      SignInRequested(email: email, password: password),
                    );
                  },
                  showDisplayNameField: false,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    context.read<AuthBloc>().add(AnonymousSignInRequested());
                  },
                  icon: const Icon(Icons.person_outline),
                  label: const Text('Continue as Guest'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<AuthBloc>(),
                          child: const RegisterScreen(),
                        ),
                      ),
                    );
                  },
                  child: const Text('Don\'t have an account? Sign up'),
                ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}