import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';

import '../data/driver_firebase_auth_repository.dart';

// ── Repository ─────────────────────────────────────────────────────────────────

final driverAuthRepositoryProvider = Provider<AuthRepository>((ref) {
  return DriverFirebaseAuthRepository();
});

// ── Auth UID stream ────────────────────────────────────────────────────────────

final driverAuthUidProvider = StreamProvider<String?>((ref) {
  return ref.watch(driverAuthRepositoryProvider).userIdStream;
});

// ── Current driver UserModel ───────────────────────────────────────────────────

final driverCurrentUserProvider = FutureProvider<UserModel?>((ref) async {
  final uid = ref.watch(driverAuthUidProvider).valueOrNull;
  if (uid == null) return null;
  return ref.watch(driverAuthRepositoryProvider).getUser(uid);
});

// ── OTP flow state ─────────────────────────────────────────────────────────────

sealed class DriverOtpFlowState {
  const DriverOtpFlowState();
}

class DriverOtpFlowIdle extends DriverOtpFlowState {
  const DriverOtpFlowIdle();
}

class DriverOtpFlowSending extends DriverOtpFlowState {
  const DriverOtpFlowSending();
}

class DriverOtpFlowCodeSent extends DriverOtpFlowState {
  const DriverOtpFlowCodeSent({
    required this.verificationId,
    required this.phoneNumber,
    this.resendToken,
  });
  final String verificationId;
  final String phoneNumber;
  final int? resendToken;
}

class DriverOtpFlowVerifying extends DriverOtpFlowState {
  const DriverOtpFlowVerifying();
}

class DriverOtpFlowError extends DriverOtpFlowState {
  const DriverOtpFlowError(this.message);
  final String message;
}

class DriverOtpFlowNotifier extends Notifier<DriverOtpFlowState> {
  @override
  DriverOtpFlowState build() => const DriverOtpFlowIdle();

  AuthRepository get _repo => ref.read(driverAuthRepositoryProvider);

  Future<void> sendOtp(String phoneNumber) async {
    state = const DriverOtpFlowSending();
    await _repo.verifyPhone(
      phoneNumber,
      onCodeSent: (verificationId, resendToken) {
        state = DriverOtpFlowCodeSent(
          verificationId: verificationId,
          phoneNumber: phoneNumber,
          resendToken: resendToken,
        );
      },
      onError: (e) => state = DriverOtpFlowError(e.message),
    );
  }

  Future<bool> verifyOtp(String otp) async {
    final current = state;
    if (current is! DriverOtpFlowCodeSent) return false;

    state = const DriverOtpFlowVerifying();
    try {
      await _repo.signInWithOtp(
        verificationId: current.verificationId,
        otp: otp,
      );
      state = const DriverOtpFlowIdle();
      return true;
    } on AppException catch (e) {
      state = DriverOtpFlowError(e.message);
      return false;
    }
  }

  Future<void> resendOtp() async {
    final current = state;
    if (current is! DriverOtpFlowCodeSent) return;
    await sendOtp(current.phoneNumber);
  }

  void reset() => state = const DriverOtpFlowIdle();
}

final driverOtpFlowProvider =
    NotifierProvider<DriverOtpFlowNotifier, DriverOtpFlowState>(
  DriverOtpFlowNotifier.new,
);

// ── Sign out ───────────────────────────────────────────────────────────────────

Future<void> driverSignOut(WidgetRef ref) async {
  await ref.read(driverAuthRepositoryProvider).signOut();
  ref.invalidate(driverCurrentUserProvider);
}
