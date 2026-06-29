import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import 'prayer_repository.dart';
import 'prayer_request.dart';

part 'prayer_providers.g.dart';

@riverpod
PrayerRepository prayerRepository(PrayerRepositoryRef ref) =>
    PrayerRepository(FirebaseFirestore.instance);

/// Live list of the signed-in user's prayer requests (newest first).
/// Emits an empty list when signed out.
@riverpod
Stream<List<PrayerRequest>> prayerRequests(PrayerRequestsRef ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const []);
  return ref.watch(prayerRepositoryProvider).watchRequests(user.uid);
}

/// Live single prayer request by id. Null while loading or if not found.
@riverpod
Stream<PrayerRequest?> prayerRequest(PrayerRequestRef ref, String id) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('prayer_requests')
      .doc(id)
      .snapshots()
      .map((s) => s.exists ? PrayerRequest.fromSnapshot(s) : null);
}
