import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../shared/user/user_providers.dart';
import '../../data/firebase_auth_repository.dart';
import '../../domain/auth_repository.dart';

part 'auth_providers.g.dart';

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) => FirebaseAuthRepository(
      fb.FirebaseAuth.instance,
      GoogleSignIn(),
      ref.watch(userRepositoryProvider),
    );

/// Emits the current [AppUser] (or null) and updates on sign-in / sign-out.
/// The router watches this to decide which screen to show.
@riverpod
Stream<AppUser?> authState(AuthStateRef ref) =>
    ref.watch(authRepositoryProvider).watchAuthState();
