import 'dart:async';

import 'auth_remote_data_source.dart';

class MockAuthDataSource implements AuthRemoteDataSource {
  final StreamController<String?> _authStateController = StreamController<String?>.broadcast();
  String? _currentUserId;

  MockAuthDataSource() {
    // Simulate no user logged in initially
    _authStateController.add(null);
  }

  @override
  Stream<String?> get authStateChanges => _authStateController.stream;

  @override
  Future<String> signInWithEmailAndPassword(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Simple validation for demo
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password cannot be empty');
    }

    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }

    // Simulate successful login
    _currentUserId = 'mock_user_${email.hashCode.abs()}';
    _authStateController.add(_currentUserId);
    
    return _currentUserId!;
  }

  @override
  Future<String> createUserWithEmailAndPassword(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1000));

    // Simple validation for demo
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password cannot be empty');
    }

    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }

    if (!email.contains('@')) {
      throw Exception('Invalid email format');
    }

    // Simulate successful account creation
    _currentUserId = 'mock_user_${email.hashCode.abs()}';
    _authStateController.add(_currentUserId);
    
    return _currentUserId!;
  }

  @override
  Future<String> signInAnonymously() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Create anonymous user ID
    _currentUserId = 'mock_anon_${DateTime.now().millisecondsSinceEpoch}';
    _authStateController.add(_currentUserId);

    return _currentUserId!;
  }

  @override
  Future<void> signOut() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    _currentUserId = null;
    _authStateController.add(null);
  }

  @override
  String? getCurrentUserId() {
    return _currentUserId;
  }

  @override
  Map<String, dynamic>? getCurrentUserData() {
    if (_currentUserId == null) return null;

    return {
      'displayName': 'Mock User',
      'email': 'mock@example.com',
      'isAnonymous': _currentUserId!.startsWith('mock_anon_'),
    };
  }

  void dispose() {
    _authStateController.close();
  }
}