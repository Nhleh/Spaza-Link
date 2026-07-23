import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';

import '../data/firebase_auth_repository.dart';

// ── Repository ─────────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
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
