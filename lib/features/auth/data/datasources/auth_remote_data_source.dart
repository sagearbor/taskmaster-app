abstract class AuthRemoteDataSource {
  Stream<String?> get authStateChanges;
  Future<String> signInWithEmailAndPassword(String email, String password);
  Future<String> createUserWithEmailAndPassword(String email, String password);
  Future<String> signInAnonymously();
  Future<void> signOut();
  String? getCurrentUserId();
  Map<String, dynamic>? getCurrentUserData(); // Returns displayName, email, isAnonymous
}