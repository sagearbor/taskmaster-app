part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object> get props => [user];
}

/// Emitted after a successful profile edit. Extends [AuthAuthenticated] so the
/// app stays on the authenticated screens; the profile screen listens for this
/// specific type to show a confirmation and pop.
class AuthProfileUpdated extends AuthAuthenticated {
  const AuthProfileUpdated({required super.user});
}

/// Emitted when a profile edit fails but the user is still signed in. Extends
/// [AuthAuthenticated] so we never flip back to the login screen on a
/// non-fatal error.
class AuthProfileUpdateFailure extends AuthAuthenticated {
  final String message;

  const AuthProfileUpdateFailure({required super.user, required this.message});

  @override
  List<Object> get props => [user, message];
}

class AuthUnauthenticated extends AuthState {}

/// Transient one-shot state: a password-reset email was sent.
class AuthPasswordResetSent extends AuthState {
  final String email;

  const AuthPasswordResetSent({required this.email});

  @override
  List<Object> get props => [email];
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object> get props => [message];
}
