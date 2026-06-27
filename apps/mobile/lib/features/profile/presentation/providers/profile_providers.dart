import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../shared/user/user_profile.dart';
import '../../../../shared/user/user_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

part 'profile_providers.g.dart';

/// Live stream of the currently signed-in user's Firestore profile.
/// Emits null when signed out or before the doc has been created.
@riverpod
Stream<UserProfile?> userProfile(UserProfileRef ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchProfile(user.uid);
}
