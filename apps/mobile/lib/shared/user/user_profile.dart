import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore-backed user document at `users/{uid}`.
///
/// Mirrors Firebase Auth (email/displayName/photoUrl) plus extra app-level
/// fields (preferredTranslation, settings, etc.) that don't exist in Auth.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.preferredTranslation,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? preferredTranslation;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserProfile.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final d = snap.data() ?? const <String, dynamic>{};
    return UserProfile(
      uid: snap.id,
      email: d['email'] as String? ?? '',
      displayName: d['displayName'] as String?,
      photoUrl: d['photoUrl'] as String?,
      preferredTranslation: d['preferredTranslation'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
