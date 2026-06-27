import 'dart:async';

import 'telephone_remote_data_source.dart';

/// In-memory [TelephoneRemoteDataSource] for offline development and tests.
///
/// Mirrors the Firestore semantics closely enough to exercise the full game
/// loop: per-session broadcast streams, an atomic [updateSession] (trivially
/// atomic here since everything runs on one isolate), and invite-code lookup.
class MockTelephoneDataSource implements TelephoneRemoteDataSource {
  final Map<String, Map<String, dynamic>> _sessions = {};
  final Map<String, StreamController<Map<String, dynamic>?>> _controllers = {};

  StreamController<Map<String, dynamic>?> _controllerFor(String id) {
    return _controllers.putIfAbsent(
      id,
      () => StreamController<Map<String, dynamic>?>.broadcast(),
    );
  }

  void _emit(String id) {
    final controller = _controllerFor(id);
    final data = _sessions[id];
    controller.add(data == null ? null : Map<String, dynamic>.from(data));
  }

  @override
  Stream<Map<String, dynamic>?> watchSession(String sessionId) async* {
    final current = _sessions[sessionId];
    yield current == null ? null : Map<String, dynamic>.from(current);
    yield* _controllerFor(sessionId).stream;
  }

  @override
  Future<void> createSession(Map<String, dynamic> data) async {
    final id = data['id'] as String;
    _sessions[id] = Map<String, dynamic>.from(data);
    _emit(id);
  }

  @override
  Future<String?> findSessionIdByCode(String inviteCode) async {
    for (final entry in _sessions.entries) {
      if (entry.value['inviteCode'] == inviteCode) return entry.key;
    }
    return null;
  }

  @override
  Future<void> updateSession(
    String sessionId,
    Map<String, dynamic> Function(Map<String, dynamic> current) transform,
  ) async {
    final current = _sessions[sessionId];
    if (current == null) {
      throw Exception('Session not found: $sessionId');
    }
    final next = transform(Map<String, dynamic>.from(current));
    _sessions[sessionId] = Map<String, dynamic>.from(next);
    _emit(sessionId);
  }

  void dispose() {
    for (final c in _controllers.values) {
      c.close();
    }
    _controllers.clear();
  }
}
