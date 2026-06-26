import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'auth_remote_data_source.dart';

class FirebaseAuthDataSource implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  // Best-effort cache so the synchronous getCurrentUserData() can surface the
  // avatar emoji once it has been loaded via getCurrentUserProfile().
  String? _cachedAvatarEmoji;

  FirebaseAuthDataSource({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _usersCollection = 'users';

  @override
  Stream<String?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((user) => user?.uid);
  }

  @override
  Future<String> signInWithEmailAndPassword(
      String email, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    _cachedAvatarEmoji = null;
    return credential.user!.uid;
  }

  @override
  Future<String> createUserWithEmailAndPassword(
      String email, String password) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    _cachedAvatarEmoji = null;
    return credential.user!.uid;
  }

  @override
  Future<String> signInAnonymously() async {
    final credential = await _firebaseAuth.signInAnonymously();
    _cachedAvatarEmoji = null;
    return credential.user!.uid;
  }

  @override
  Future<void> signOut() async {
    _cachedAvatarEmoji = null;
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
      'avatarEmoji': _cachedAvatarEmoji,
    };
  }

  @override
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;

    String? avatarEmoji;
    DateTime? createdAt;
    try {
      final doc =
          await _firestore.collection(_usersCollection).doc(user.uid).get();
      final data = doc.data();
      if (data != null) {
        avatarEmoji = data['avatarEmoji'] as String?;
        final created = data['createdAt'];
        if (created is Timestamp) {
          createdAt = created.toDate();
        } else if (created is String) {
          createdAt = DateTime.tryParse(created);
        }
      }
    } catch (_) {
      // Profile doc is optional; fall back to auth-only data.
    }
    _cachedAvatarEmoji = avatarEmoji;

    return {
      'displayName': user.displayName,
      'email': user.email,
      'isAnonymous': user.isAnonymous,
      'avatarEmoji': avatarEmoji,
      if (createdAt != null) 'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  Future<void> updateProfile({String? displayName, String? avatarEmoji}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('No signed-in user to update');
    }
    if (displayName != null && displayName.trim().isNotEmpty) {
      await user.updateDisplayName(displayName.trim());
    }
    if (avatarEmoji != null) {
      _cachedAvatarEmoji = avatarEmoji.isEmpty ? null : avatarEmoji;
    }
    // Persist to the users/{uid} doc (merge) so it survives across sessions.
    final update = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (displayName != null && displayName.trim().isNotEmpty) {
      update['displayName'] = displayName.trim();
    }
    if (avatarEmoji != null) {
      update['avatarEmoji'] = avatarEmoji.isEmpty ? null : avatarEmoji;
    }
    if (user.email != null) update['email'] = user.email;
    await _firestore
        .collection(_usersCollection)
        .doc(user.uid)
        .set(update, SetOptions(merge: true));
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<String> upgradeGuestAccount(
      String email, String password, String displayName) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || !user.isAnonymous) {
      throw Exception('Only a guest account can be upgraded');
    }
    // Linking preserves the uid (and therefore all existing game data).
    final credential = firebase_auth.EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    final result = await user.linkWithCredential(credential);
    final linkedUser = result.user!;
    if (displayName.trim().isNotEmpty) {
      await linkedUser.updateDisplayName(displayName.trim());
    }
    await _firestore.collection(_usersCollection).doc(linkedUser.uid).set({
      'displayName': displayName.trim().isNotEmpty
          ? displayName.trim()
          : email.split('@')[0],
      'email': email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return linkedUser.uid;
  }
}
