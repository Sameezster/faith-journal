import 'package:firebase_auth/firebase_auth.dart' as fb;

/// Maps Firebase auth errors to short, user-friendly messages.
/// Add new cases here as you encounter them in QA.
String friendlyAuthError(Object e) {
  if (e is fb.FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account with that email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'network-request-failed':
        return 'Network error — check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'cancelled':
        return 'Sign-in cancelled.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
    }
    return e.message ?? 'Authentication failed (${e.code}).';
  }
  return 'Something went wrong. Please try again.';
}
