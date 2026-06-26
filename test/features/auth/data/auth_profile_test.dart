import 'package:flutter_test/flutter_test.dart';
import 'package:taskcaster_app/features/auth/data/datasources/mock_auth_data_source.dart';
import 'package:taskcaster_app/features/auth/data/repositories/auth_repository_impl.dart';

void main() {
  group('AuthRepositoryImpl.updateProfile (mock)', () {
    late MockAuthDataSource dataSource;
    late AuthRepositoryImpl repository;

    setUp(() {
      dataSource = MockAuthDataSource();
      repository = AuthRepositoryImpl(dataSource);
    });

    tearDown(() => dataSource.dispose());

    test('updates display name and avatar emoji', () async {
      await repository.signInWithEmailAndPassword(
          'sophie@example.com', 'password123');

      final updated = await repository.updateProfile(
        displayName: 'Sophie A',
        avatarEmoji: '🏆',
      );

      expect(updated.displayName, 'Sophie A');
      expect(updated.avatarEmoji, '🏆');

      // A fresh read reflects the change.
      final current = await repository.getCurrentUser();
      expect(current?.displayName, 'Sophie A');
      expect(current?.avatarEmoji, '🏆');
    });

    test('upgradeGuestAccount keeps the same uid (preserves data)', () async {
      final guest = await repository.signInAnonymously();
      expect(repository.isCurrentUserAnonymous(), isTrue);

      final upgraded = await repository.upgradeGuestAccount(
        'new@example.com',
        'password123',
        'New Name',
      );

      // Same uid → existing game data stays attached to the user.
      expect(upgraded.id, guest.id);
      expect(upgraded.email, 'new@example.com');
      expect(repository.isCurrentUserAnonymous(), isFalse);
    });

    test('sendPasswordReset rejects an invalid email', () async {
      await repository.signInWithEmailAndPassword('a@b.com', 'password123');
      expect(
        () => repository.sendPasswordReset('not-an-email'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
