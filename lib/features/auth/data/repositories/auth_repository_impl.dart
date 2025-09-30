import '../../../../core/models/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Stream<String?> get authStateChanges => remoteDataSource.authStateChanges;

  @override
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    final userId = await remoteDataSource.signInWithEmailAndPassword(email, password);
    return User(
      id: userId,
      displayName: email.split('@')[0], // Simple display name extraction
      email: email,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<User> createUserWithEmailAndPassword(String email, String password, String displayName) async {
    final userId = await remoteDataSource.createUserWithEmailAndPassword(email, password);
    return User(
      id: userId,
      displayName: displayName,
      email: email,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> signOut() => remoteDataSource.signOut();

  @override
  String? getCurrentUserId() => remoteDataSource.getCurrentUserId();

  @override
  Future<User?> getCurrentUser() async {
    final userId = getCurrentUserId();
    if (userId == null) return null;

    // In a real implementation, this would fetch user data from Firestore
    return User(
      id: userId,
      displayName: 'Current User',
      email: 'user@example.com',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<User> signInAnonymously() async {
    final userId = await remoteDataSource.signInAnonymously();
    return User(
      id: userId,
      displayName: 'Guest',
      email: null,
      createdAt: DateTime.now(),
    );
  }
}