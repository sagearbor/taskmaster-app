import '../../../../core/models/user.dart';

abstract class AuthRepository {
  Stream<String?> get authStateChanges;
  Future<User> signInWithEmailAndPassword(String email, String password);
  Future<User> createUserWithEmailAndPassword(String email, String password, String displayName);
  Future<User> signInAnonymously();
  Future<void> signOut();
  String? getCurrentUserId();
  Future<User?> getCurrentUser();
}