import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Triggered when the login button is pressed.
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Triggered on app startup to check if the user is already logged in.
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Triggered when the user signs out.
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
