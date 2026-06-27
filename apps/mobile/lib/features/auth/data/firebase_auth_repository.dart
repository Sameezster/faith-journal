import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

import '../../../shared/user/user_repository.dart';
import '../domain/auth_repository.dart';

/// Firebase-backed implementation of [AuthRepository].
///
/// On every successful sign-in/sign-up, `_users.ensureProfile(...)` is called
/// to create or refresh the corresponding `users/{uid}` Firestore document.
///
/// Apple sign-in is intentionally stubbed (`UnimplementedError`) until the
/// Apple Developer account + Sign In with Apple capability are configured.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, this._google, this._users);

  final fb.FirebaseAuth _auth;
  final GoogleSignIn _google;
  final UserRepository _users;

  @override
  Stream<AppUser?> watchAuthState() => _auth.authStateChanges().map(_toAppUser);

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = _toAppUser(cred.user)!;
    await _users.ensureProfile(user);
    return user;
  }

  @override
  Future<AppUser> registerWithEmail(
    String name,
    String email,
    String password,
  ) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user?.updateDisplayName(name);
    await cred.user?.reload();
    final user = _toAppUser(_auth.currentUser)!;
    await _users.ensureProfile(user);
    return user;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    final account = await _google.signIn();
    if (account == null) {
      throw fb.FirebaseAuthException(
        code: 'cancelled',
        message: 'Sign-in cancelled',
      );
    }
    final googleAuth = await account.authentication;
    final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    final user = _toAppUser(cred.user)!;
    await _users.ensureProfile(user);
    return user;
  }

  @override
  Future<AppUser> signInWithApple() async {
    throw UnimplementedError(
      'Apple Sign-In requires Apple Developer setup. See CONTRIBUTING.md.',
    );
  }

  @override
  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  @override
  Future<void> signOut() => Future.wait<void>([
        _auth.signOut(),
        _google.signOut().catchError((_) => null),
      ]);

  AppUser? _toAppUser(fb.User? u) => u == null
      ? null
      : AppUser(
          uid: u.uid,
          email: u.email ?? '',
          displayName: u.displayName,
          photoUrl: u.photoURL,
        );
}
