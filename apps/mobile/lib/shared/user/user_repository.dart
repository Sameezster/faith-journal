import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/auth/domain/auth_repository.dart';
import 'user_profile.dart';

/// CRUD for `users/{uid}` documents in Firestore.
///
/// [ensureProfile] is called on every successful sign-in. It creates the doc
/// on first login (stamping `createdAt`) and just refreshes `updatedAt` on
/// subsequent logins.
class UserRepository {
  UserRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// Realtime stream of the user's profile doc. Emits null until the doc exists.
  Stream<UserProfile?> watchProfile(String uid) =>
      _users.doc(uid).snapshots().map(
            (snap) => snap.exists ? UserProfile.fromSnapshot(snap) : null,
          );

  /// One-shot read.
  Future<UserProfile?> getProfile(String uid) async {
    final snap = await _users.doc(uid).get();
    return snap.exists ? UserProfile.fromSnapshot(snap) : null;
  }

  /// Create or refresh the profile doc for an authenticated user.
  Future<void> ensureProfile(AppUser user) async {
    final ref = _users.doc(user.uid);
    final snap = await ref.get();
    final now = FieldValue.serverTimestamp();
    if (!snap.exists) {
      await ref.set({
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoUrl,
        'createdAt': now,
        'updatedAt': now,
      });
    } else {
      // Refresh mutable fields from Auth (in case the user changed their name
      // or photo via Google) without touching `createdAt`.
      await ref.update({
        'email': user.email,
        if (user.displayName != null) 'displayName': user.displayName,
        if (user.photoUrl != null) 'photoUrl': user.photoUrl,
        'updatedAt': now,
      });
    }
  }

  /// Update arbitrary fields on the profile doc.
  Future<void> updateProfile(String uid, Map<String, dynamic> patch) =>
      _users.doc(uid).update({
        ...patch,
        'updatedAt': FieldValue.serverTimestamp(),
      });
}
