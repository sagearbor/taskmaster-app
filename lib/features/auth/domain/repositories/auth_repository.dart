import '../../../../core/models/user.dart';

abstract class AuthRepository {
  Stream<String?> get authStateChanges;
  Future<User> signInWithEmailAndPassword(String email, String password);
  Future<User> createUserWithEmailAndPassword(
      String email, String password, String displayName);
  Future<User> signInAnonymously();
  Future<void> signOut();
  String? getCurrentUserId();
  Future<User?> getCurrentUser();
  bool isCurrentUserAnonymous();

  /// Update the current user's profile. Returns the updated [User].
  Future<User> updateProfile({String? displayName, String? avatarEmoji});

  /// Send a password-reset email to [email].
  Future<void> sendPasswordReset(String email);

  /// Convert the current anonymous (guest) user into a permanent email/password
  /// account, preserving their uid (and all existing game data). Returns the
  /// upgraded [User].
  Future<User> upgradeGuestAccount(
      String email, String password, String displayName);
}
