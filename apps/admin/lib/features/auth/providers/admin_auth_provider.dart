import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';

import '../data/admin_firebase_auth_repository.dart';

// ── Repository ─────────────────────────────────────────────────────────────────

final adminAuthRepositoryProvider = Provider<AuthRepository>((ref) {
  return AdminFirebaseAuthRepository();
});

// ── Auth UID stream ────────────────────────────────────────────────────────────

final adminAuthUidProvider = StreamProvider<String?>((ref) {
  return ref.watch(adminAuthRepositoryProvider).userIdStream;
});

// ── Current admin UserModel ────────────────────────────────────────────────────

final adminCurrentUserProvider = FutureProvider<UserModel?>((ref) async {
  final uid = ref.watch(adminAuthUidProvider).valueOrNull;
  if (uid == null) return null;
  return ref.watch(adminAuthRepositoryProvider).getUser(uid);
});

// ── Sign-in state ─────────────────────────────────────────────────────────────

sealed class AdminSignInState {
  const AdminSignInState();
}

class AdminSignInIdle extends AdminSignInState {
  const AdminSignInIdle();
}

class AdminSignInLoading extends AdminSignInState {
  const AdminSignInLoading();
}

class AdminSignInError extends AdminSignInState {
  const AdminSignInError(this.message);
  final String message;
}

class AdminSignInNotifier extends Notifier<AdminSignInState> {
  @override
  AdminSignInState build() => const AdminSignInIdle();

  AuthRepository get _repo => ref.read(adminAuthRepositoryProvider);

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = const AdminSignInLoading();
    try {
      await _repo.signInWithEmailAndPassword(email: email, password: password);
      state = const AdminSignInIdle();
      return true;
    } on AppException catch (e) {
      state = AdminSignInError(e.message);
      return false;
    }
  }

  void reset() => state = const AdminSignInIdle();
}

final adminSignInProvider =
    NotifierProvider<AdminSignInNotifier, AdminSignInState>(
  AdminSignInNotifier.new,
);

// ── Sign out ───────────────────────────────────────────────────────────────────

Future<void> adminSignOut(WidgetRef ref) async {
  await ref.read(adminAuthRepositoryProvider).signOut();
  ref.invalidate(adminCurrentUserProvider);
}
