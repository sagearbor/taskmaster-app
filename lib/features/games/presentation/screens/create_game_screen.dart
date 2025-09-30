import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/repositories/game_repository.dart';
import '../bloc/games_bloc.dart';

class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({super.key});

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gameNameController = TextEditingController();
  String _selectedJudge = 'creator';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print('[CreateGameScreen] initState called');
  }

  @override
  void dispose() {
    _gameNameController.dispose();
    super.dispose();
  }

  String? _validateGameName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Game name is required';
    }
    if (value.length < 3) {
      return 'Game name must be at least 3 characters';
    }
    if (value.length > 50) {
      return 'Game name must be less than 50 characters';
    }
    return null;
  }

  Future<void> _createGame() async {
    print('[CreateGameScreen] _createGame called');

    try {
      if (!_formKey.currentState!.validate()) {
        print('[CreateGameScreen] Form validation failed');
        return;
      }
      print('[CreateGameScreen] Form validation passed');

      final authState = context.read<AuthBloc>().state;
      print('[CreateGameScreen] AuthBloc state: $authState');

      if (authState is! AuthAuthenticated) {
        print('[CreateGameScreen] User not authenticated');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to create a game'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      print('[CreateGameScreen] User authenticated: ${authState.user.id}');

      setState(() {
        _isLoading = true;
      });
      print('[CreateGameScreen] Set loading to true');

      print('[CreateGameScreen] Getting GameRepository from service locator...');
      final gameRepository = sl<GameRepository>();
      print('[CreateGameScreen] Got GameRepository: $gameRepository');

      final judgeId = _selectedJudge == 'creator'
          ? authState.user.id
          : authState.user.id; // For now, creator is always judge

      print('[CreateGameScreen] Calling createGame with: gameName=${_gameNameController.text.trim()}, creatorId=${authState.user.id}, judgeId=$judgeId');
      await gameRepository.createGame(
        _gameNameController.text.trim(),
        authState.user.id,
        judgeId,
      );
      print('[CreateGameScreen] Game created successfully!');

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Game created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('[CreateGameScreen] ERROR: $e');
      print('[CreateGameScreen] Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create game: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('[CreateGameScreen] Building...');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Game'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Let\'s Get Started!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E7D32),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Create a game and invite your friends to join',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _gameNameController,
                decoration: InputDecoration(
                  labelText: 'Game Name',
                  hintText: 'Enter a fun name for your game',
                  helperText: 'At least 3 characters required',
                  prefixIcon: const Icon(Icons.sports_esports),
                  suffixIcon: _gameNameController.text.length >= 3
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                ),
                validator: _validateGameName,
                enabled: !_isLoading,
                textInputAction: TextInputAction.next,
                maxLength: 50,
                onChanged: (value) => setState(() {}), // Rebuild to show check icon
              ),
              const SizedBox(height: 24),
              Text(
                'Who will be the judge?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              RadioListTile<String>(
                title: const Text('I will be the judge'),
                subtitle: const Text('You will review and score all submissions'),
                value: 'creator',
                groupValue: _selectedJudge,
                onChanged: _isLoading ? null : (value) {
                  setState(() {
                    _selectedJudge = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'How it works',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Create your game and share the invite code\n'
                      '2. Friends join using the code\n'
                      '3. Add tasks and start the game\n'
                      '4. Players submit videos for each task\n'
                      '5. Judge scores submissions and declares winner!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _createGame,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Game'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}