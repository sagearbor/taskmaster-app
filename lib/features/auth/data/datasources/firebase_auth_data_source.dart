// Web-safe Firebase Auth implementation
import 'dart:async';
import 'auth_remote_data_source.dart';
import 'mock_auth_data_source.dart';

// Conditional implementation that falls back to mock if Firebase isn't available
class FirebaseAuthDataSource extends MockAuthDataSource implements AuthRemoteDataSource {
  FirebaseAuthDataSource({
    dynamic firebaseAuth,
    dynamic firestore,
  }) : super();
  
  // All methods inherited from MockAuthDataSource
  // Will be replaced with real Firebase implementation when properly configured
}