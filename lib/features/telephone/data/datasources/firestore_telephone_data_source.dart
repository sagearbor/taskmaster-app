import 'package:cloud_firestore/cloud_firestore.dart';

import 'telephone_remote_data_source.dart';

/// Firestore-backed [TelephoneRemoteDataSource].
///
/// Sessions live in their own top-level `telephone_sessions` collection. The
/// key reliability feature is [updateSession], which runs the supplied
/// transform inside a Firestore transaction so that simultaneous player
/// submissions (the norm in this game) are serialized — no lost writes, no
/// double-advanced steps.
class FirestoreTelephoneDataSource implements TelephoneRemoteDataSource {
  final FirebaseFirestore _firestore;

  FirestoreTelephoneDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _collection = 'telephone_sessions';

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection(_collection);

  @override
  Stream<Map<String, dynamic>?> watchSession(String sessionId) {
    return _sessions.doc(sessionId).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data()!;
      data['id'] = snap.id;
      return data;
    });
  }

  @override
  Future<void> createSession(Map<String, dynamic> data) async {
    final id = data['id'] as String;
    await _sessions.doc(id).set(data);
  }

  @override
  Future<String?> findSessionIdByCode(String inviteCode) async {
    final query = await _sessions
        .where('inviteCode', isEqualTo: inviteCode)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return query.docs.first.id;
  }

  @override
  Future<void> updateSession(
    String sessionId,
    Map<String, dynamic> Function(Map<String, dynamic> current) transform,
  ) async {
    final ref = _sessions.doc(sessionId);
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) {
        throw Exception('Session not found: $sessionId');
      }
      final current = snap.data()!;
      current['id'] = ref.id;
      final next = transform(current);
      // Strip the synthetic id before persisting (the doc id is the source of
      // truth); keeping it is harmless but avoids a redundant field.
      next.remove('id');
      txn.set(ref, next);
    });
  }
}
