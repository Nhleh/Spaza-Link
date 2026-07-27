import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';

import '../data/supabase_auth_repository.dart';

// ── Repository ─────────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<SupabaseAuthRepository>((ref) {
  return SupabaseAuthRepository();
});

// ── Auth UID stream ────────────────────────────────────────────────────────────

/// Emits the current user's UID, or null when signed out.
final authUidProvider = StreamProvider<String?>((ref) {
  return ref.watch(authRepositoryProvider).userIdStream;
});

// ── Current UserModel ──────────────────────────────────────────────────────────

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final uid = ref.watch(authUidProvider).valueOrNull;
  if (uid == null) return null;
  return ref.watch(authRepositoryProvider).getUser(uid);
});

// ── Current ShopModel ──────────────────────────────────────────────────────────

final currentShopProvider = FutureProvider<ShopModel?>((ref) async {
  final uid = ref.watch(authUidProvider).valueOrNull;
  if (uid == null) return null;
  return ref.watch(authRepositoryProvider).getShopByOwnerId(uid);
});

// ── Email / cellphone + password auth actions ───────────────────────────────────

/// Drives sign-in and account registration, exposing a loading/error state
/// the login and register screens can react to.
class AuthActionNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  SupabaseAuthRepository get _repo => ref.read(authRepositoryProvider);

  /// Signs in with an email or cellphone [identifier] plus [password].
  /// Returns true on success; the router redirect handles navigation.
  Future<bool> login({
    required String identifier,
    required String password,
    required bool isEmail,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.signInWithIdentifier(
        identifier: identifier,
        password: password,
        isEmail: isEmail,
      );
      state = const AsyncValue.data(null);
      return true;
    } on AppException catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(
        ServerException(message: 'Sign in failed: $e'),
        st,
      );
      return false;
    }
  }

  /// Creates the account (email/password auth + user profile) and the shop in
  /// one step. [useEmailLogin] chooses email vs cellphone as the sign-in id.
  Future<bool> registerAccountAndShop({
    required String name,
    required String email,
    required String phone,
    required String password,
    required bool useEmailLogin,
    required String shopName,
    required String physicalAddress,
    required String city,
    required String province,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.registerAccount(
        name: name,
        email: email,
        phone: phone,
        password: password,
        useEmailLogin: useEmailLogin,
      );
      // Don't create a duplicate shop if this account already registered one.
      final existingShop = await _repo.getShopByOwnerId(user.uid);
      if (existingShop == null) {
        await _repo.createShop(ShopModel(
          ownerId: user.uid,
          shopName: shopName,
          ownerName: name,
          physicalAddress: physicalAddress,
          city: city,
          province: province,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
      ref.invalidate(currentShopProvider);
      state = const AsyncValue.data(null);
      return true;
    } on AppException catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(
        ServerException(message: 'Registration failed: $e'),
        st,
      );
      return false;
    }
  }
}

final authActionProvider =
    NotifierProvider<AuthActionNotifier, AsyncValue<void>>(
  AuthActionNotifier.new,
);

// ── Auth state notifier ────────────────────────────────────────────────────────

/// Tracks the OTP verification flow state (separate from Firebase Auth state).
sealed class OtpFlowState {
  const OtpFlowState();
}

class OtpFlowIdle extends OtpFlowState {
  const OtpFlowIdle();
}

class OtpFlowSending extends OtpFlowState {
  const OtpFlowSending();
}

class OtpFlowCodeSent extends OtpFlowState {
  const OtpFlowCodeSent({
    required this.verificationId,
    required this.phoneNumber,
    this.resendToken,
  });
  final String verificationId;
  final String phoneNumber;
  final int? resendToken;
}

class OtpFlowVerifying extends OtpFlowState {
  const OtpFlowVerifying();
}

class OtpFlowError extends OtpFlowState {
  const OtpFlowError(this.message);
  final String message;
}

class OtpFlowNotifier extends Notifier<OtpFlowState> {
  @override
  OtpFlowState build() => const OtpFlowIdle();

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> sendOtp(String phoneNumber) async {
    state = const OtpFlowSending();
    await _repo.verifyPhone(
      phoneNumber,
      onCodeSent: (verificationId, resendToken) {
        state = OtpFlowCodeSent(
          verificationId: verificationId,
          phoneNumber: phoneNumber,
          resendToken: resendToken,
        );
      },
      onError: (e) => state = OtpFlowError(e.message),
    );
  }

  Future<bool> verifyOtp(String otp) async {
    final current = state;
    if (current is! OtpFlowCodeSent) return false;

    state = const OtpFlowVerifying();
    try {
      await _repo.signInWithOtp(
        verificationId: current.verificationId,
        otp: otp,
      );
      state = const OtpFlowIdle();
      return true;
    } on AppException catch (e) {
      state = OtpFlowError(e.message);
      return false;
    }
  }

  Future<void> resendOtp() async {
    final current = state;
    if (current is! OtpFlowCodeSent) return;
    await sendOtp(current.phoneNumber);
  }

  void reset() => state = const OtpFlowIdle();
}

final otpFlowProvider = NotifierProvider<OtpFlowNotifier, OtpFlowState>(
  OtpFlowNotifier.new,
);

// ── Shop registration notifier ─────────────────────────────────────────────────

class ShopRegistrationNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<ShopModel?> register({
    required String ownerName,
    required String shopName,
    required String physicalAddress,
    required String city,
    required String province,
    required String ownerId,
    GpsLocation? gpsLocation,
    String? shopPhotoUrl,
    String? ownerIdUrl,
    String? businessRegUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      final shop = await ref.read(authRepositoryProvider).createShop(
            ShopModel(
              ownerId: ownerId,
              shopName: shopName,
              ownerName: ownerName,
              physicalAddress: physicalAddress,
              city: city,
              province: province,
              gpsLocation: gpsLocation,
              shopPhotoUrl: shopPhotoUrl,
              ownerIdUrl: ownerIdUrl,
              businessRegUrl: businessRegUrl,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
      state = const AsyncValue.data(null);
      // Invalidate so GoRouter re-evaluates redirect.
      ref.invalidate(currentShopProvider);
      return shop;
    } on AppException catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final shopRegistrationProvider =
    NotifierProvider<ShopRegistrationNotifier, AsyncValue<void>>(
  ShopRegistrationNotifier.new,
);

// ── Sign out ───────────────────────────────────────────────────────────────────

Future<void> signOut(WidgetRef ref) async {
  await ref.read(authRepositoryProvider).signOut();
  ref.invalidate(currentUserProvider);
  ref.invalidate(currentShopProvider);
}
