import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'auth_remote_data_source.dart';

class FirebaseAuthDataSource implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth _firebaseAuth;

  FirebaseAuthDataSource({
    firebase_auth.FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  @override
  Stream<String?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((user) => user?.uid);
  }

  @override
  Future<String> signInWithEmailAndPassword(String email, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user!.uid;
  }

  @override
  Future<String> createUserWithEmailAndPassword(String email, String password) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user!.uid;
  }

  @override
  Future<String> signInAnonymously() async {
    final credential = await _firebaseAuth.signInAnonymously();
    return credential.user!.uid;
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  String? getCurrentUserId() {
    return _firebaseAuth.currentUser?.uid;
  }

  @override
  Map<String, dynamic>? getCurrentUserData() {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;

    return {
      'displayName': user.displayName,
      'email': user.email,
      'isAnonymous': user.isAnonymous,
    };
  }
}