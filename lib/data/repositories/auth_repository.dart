import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;

  static const String _isLoggedInKey = 'is_logged_in';

  AuthRepository({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// Stream of [User] which will emit the current user when
  /// the authentication state changes.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Returns the current user.
  User? get currentUser => _firebaseAuth.currentUser;

  /// Checks if the user was previously logged in (persisted session).
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  /// Signs in with the provided [email] and [password].
  /// Saves login state to SharedPreferences on success.
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
  }

  /// Signs out the current user and clears persisted login state.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
  }
}
