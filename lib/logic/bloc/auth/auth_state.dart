import 'package:equatable/equatable.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, failure }

class AuthState extends Equatable {
  final AuthStatus status;
  final String? errorMessage;
  final String? uid;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.uid,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    String? uid,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      uid: uid ?? this.uid,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, uid];
}
