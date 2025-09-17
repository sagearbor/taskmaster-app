import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskmaster_app/core/models/user.dart';
import 'package:taskmaster_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:taskmaster_app/features/auth/presentation/bloc/auth_bloc.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('AuthBloc Tests', () {
    late AuthBloc authBloc;
    late MockAuthRepository mockAuthRepository;
    late User testUser;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      authBloc = AuthBloc(authRepository: mockAuthRepository);
      testUser = User(
        id: 'test_user_id',
        displayName: 'Test User',
        email: 'test@example.com',
        createdAt: DateTime.now(),
      );
    });

    tearDown(() {
      authBloc.close();
    });

    test('initial state should be AuthInitial', () {
      expect(authBloc.state, equals(AuthInitial()));
    });

    group('SignInRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when sign in is successful',
        build: () {
          when(() => mockAuthRepository.signInWithEmailAndPassword(any(), any()))
              .thenAnswer((_) async => testUser);
          return authBloc;
        },
        act: (bloc) => bloc.add(const SignInRequested(
          email: 'test@example.com',
          password: 'password123',
        )),
        expect: () => [
          AuthLoading(),
          AuthAuthenticated(user: testUser),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when sign in fails',
        build: () {
          when(() => mockAuthRepository.signInWithEmailAndPassword(any(), any()))
              .thenThrow(Exception('Invalid credentials'));
          return authBloc;
        },
        act: (bloc) => bloc.add(const SignInRequested(
          email: 'test@example.com',
          password: 'wrongpassword',
        )),
        expect: () => [
          AuthLoading(),
          const AuthError(message: 'Exception: Invalid credentials'),
        ],
      );
    });

    group('SignUpRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when sign up is successful',
        build: () {
          when(() => mockAuthRepository.createUserWithEmailAndPassword(
                any(),
                any(),
                any(),
              )).thenAnswer((_) async => testUser);
          return authBloc;
        },
        act: (bloc) => bloc.add(const SignUpRequested(
          email: 'test@example.com',
          password: 'password123',
          displayName: 'Test User',
        )),
        expect: () => [
          AuthLoading(),
          AuthAuthenticated(user: testUser),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when sign up fails',
        build: () {
          when(() => mockAuthRepository.createUserWithEmailAndPassword(
                any(),
                any(),
                any(),
              )).thenThrow(Exception('Email already in use'));
          return authBloc;
        },
        act: (bloc) => bloc.add(const SignUpRequested(
          email: 'test@example.com',
          password: 'password123',
          displayName: 'Test User',
        )),
        expect: () => [
          AuthLoading(),
          const AuthError(message: 'Exception: Email already in use'),
        ],
      );
    });

    group('SignOutRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] when sign out is successful',
        build: () {
          when(() => mockAuthRepository.signOut()).thenAnswer((_) async {});
          return authBloc;
        },
        act: (bloc) => bloc.add(SignOutRequested()),
        expect: () => [
          AuthLoading(),
          AuthUnauthenticated(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when sign out fails',
        build: () {
          when(() => mockAuthRepository.signOut())
              .thenThrow(Exception('Sign out failed'));
          return authBloc;
        },
        act: (bloc) => bloc.add(SignOutRequested()),
        expect: () => [
          AuthLoading(),
          const AuthError(message: 'Exception: Sign out failed'),
        ],
      );
    });

    group('AuthCheckRequested', () {
      blocTest<AuthBloc, AuthState>(
        'listens to auth state changes and emits corresponding states',
        build: () {
          when(() => mockAuthRepository.authStateChanges)
              .thenAnswer((_) => Stream.value('test_user_id'));
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => testUser);
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthCheckRequested()),
        expect: () => [
          AuthAuthenticated(user: testUser),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits AuthUnauthenticated when auth state is null',
        build: () {
          when(() => mockAuthRepository.authStateChanges)
              .thenAnswer((_) => Stream.value(null));
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthCheckRequested()),
        expect: () => [
          AuthUnauthenticated(),
        ],
      );
    });
  });
}