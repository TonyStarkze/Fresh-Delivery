import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:delivery_webapp/data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  AuthRepository get authRepository => _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final isLoggedIn = await _authRepository.isLoggedIn();
    if (isLoggedIn) {
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        uid: _authRepository.currentUser?.uid,
      ));
    } else {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        uid: null,
      ));
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    try {
      await _authRepository.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        uid: _authRepository.currentUser?.uid,
      ));
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: _mapFirebaseError(e.code),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'An unexpected error occurred.',
      ));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.signOut();
    emit(state.copyWith(
      status: AuthStatus.unauthenticated,
      uid: null,
    ));
  }

  /// Maps Firebase error codes to user-friendly messages.
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many login attempts. Try again later.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
