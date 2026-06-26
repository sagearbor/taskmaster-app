import 'package:flutter_test/flutter_test.dart';
import 'package:taskcaster_app/core/models/user.dart';

void main() {
  group('User model', () {
    test('round-trips avatarEmoji and photoUrl through toMap/fromMap', () {
      final user = User(
        id: 'u1',
        displayName: 'Sophie',
        email: 'sophie@example.com',
        createdAt: DateTime(2025, 3, 14, 9, 30),
        avatarEmoji: '🦊',
        photoUrl: 'https://example.com/p.png',
      );

      final restored = User.fromMap(user.toMap());

      expect(restored, equals(user));
      expect(restored.avatarEmoji, '🦊');
      expect(restored.photoUrl, 'https://example.com/p.png');
    });

    test('fromMap tolerates missing avatarEmoji/photoUrl (backward compatible)',
        () {
      final legacy = {
        'id': 'u2',
        'displayName': 'Legacy',
        'email': null,
        'createdAt': DateTime(2024, 1, 1).toIso8601String(),
        // no avatarEmoji / photoUrl keys
      };

      final user = User.fromMap(legacy);

      expect(user.id, 'u2');
      expect(user.avatarEmoji, isNull);
      expect(user.photoUrl, isNull);
    });

    test('copyWith updates avatarEmoji while preserving other fields', () {
      final user = User(
        id: 'u3',
        displayName: 'Pat',
        createdAt: DateTime(2025, 1, 1),
      );

      final updated = user.copyWith(avatarEmoji: '🚀');

      expect(updated.avatarEmoji, '🚀');
      expect(updated.id, 'u3');
      expect(updated.displayName, 'Pat');
      // Original is unchanged (immutability).
      expect(user.avatarEmoji, isNull);
    });
  });
}
