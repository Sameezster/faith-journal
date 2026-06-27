/// Auth repository interface (implemented in data/ over Firebase Auth).
abstract interface class AuthRepository {
  Stream<AppUser?> watchAuthState();
  Future<AppUser> signInWithEmail(String email, String password);
  Future<AppUser> registerWithEmail(String name, String email, String password);
  Future<AppUser> signInWithGoogle();
  Future<AppUser> signInWithApple();
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
}

class AppUser {
  const AppUser(
      {required this.uid,
      required this.email,
      this.displayName,
      this.photoUrl});
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
}
