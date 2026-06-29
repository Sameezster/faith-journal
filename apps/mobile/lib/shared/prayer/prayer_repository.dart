import 'package:cloud_firestore/cloud_firestore.dart';

import 'prayer_request.dart';

/// CRUD for prayer requests stored at `users/{uid}/prayer_requests/{id}`.
class PrayerRepository {
  PrayerRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _requests(String uid) =>
      _firestore.collection('users').doc(uid).collection('prayer_requests');

  /// Live stream of all prayer requests, newest first.
  Stream<List<PrayerRequest>> watchRequests(String uid) => _requests(uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((q) => q.docs.map(PrayerRequest.fromSnapshot).toList());

  Future<PrayerRequest?> getRequest(String uid, String id) async {
    final snap = await _requests(uid).doc(id).get();
    return snap.exists ? PrayerRequest.fromSnapshot(snap) : null;
  }

  /// Create a new prayer.
  Future<String> createRequest(
    String uid, {
    required String title,
    required String description,
    PrayerStatus status = PrayerStatus.active,
    String? category,
    DateTime? date,
  }) async {
    final now = FieldValue.serverTimestamp();
    final ref = await _requests(uid).add({
      'title': title,
      'description': description,
      'status': status.slug,
      if (category != null) 'category': category,
      if (date != null) 'date': Timestamp.fromDate(date),
      'createdAt': now,
      'updatedAt': now,
      if (status == PrayerStatus.answered) 'answeredAt': now,
    });
    return ref.id;
  }

  /// Patch an existing prayer. Only the provided fields are written.
  /// `answeredAt` is set/cleared based on status transitions.
  Future<void> updateRequest(
    String uid,
    String id, {
    String? title,
    String? description,
    PrayerStatus? status,
    String? category,
    DateTime? date,
    bool clearCategory = false,
    bool clearDate = false,
  }) =>
      _requests(uid).doc(id).update({
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (status != null) ...{
          'status': status.slug,
          'answeredAt': status == PrayerStatus.answered
              ? FieldValue.serverTimestamp()
              : FieldValue.delete(),
        },
        if (category != null) 'category': category,
        if (clearCategory) 'category': FieldValue.delete(),
        if (date != null) 'date': Timestamp.fromDate(date),
        if (clearDate) 'date': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> deleteRequest(String uid, String id) =>
      _requests(uid).doc(id).delete();
}
