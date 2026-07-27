import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';

import '../../auth/providers/admin_auth_provider.dart';
import '../data/firebase_shop_repository.dart';

final shopRepositoryProvider = Provider<FirebaseShopRepository>((ref) {
  return FirebaseShopRepository();
});

/// Shops filtered by status ('pending', 'approved', 'rejected', 'suspended').
/// Pass null (empty string sentinel) for all shops.
final shopsByStatusProvider =
    StreamProvider.family<List<ShopModel>, String?>((ref, status) {
  return ref.watch(shopRepositoryProvider).watchShops(status: status);
});

// ── Approve / reject management ──────────────────────────────────────────────

sealed class ShopManagementState {
  const ShopManagementState();
}

class ShopManagementIdle extends ShopManagementState {
  const ShopManagementIdle();
}

class ShopManagementLoading extends ShopManagementState {
  const ShopManagementLoading();
}

class ShopManagementSuccess extends ShopManagementState {
  const ShopManagementSuccess(this.message);
  final String message;
}

class ShopManagementError extends ShopManagementState {
  const ShopManagementError(this.message);
  final String message;
}

class ShopManagementNotifier extends Notifier<ShopManagementState> {
  @override
  ShopManagementState build() => const ShopManagementIdle();

  FirebaseShopRepository get _repo => ref.read(shopRepositoryProvider);

  Future<void> approve(String shopId) async {
    final adminUid = ref.read(adminAuthUidProvider).valueOrNull;
    if (adminUid == null) {
      state = const ShopManagementError('Not signed in.');
      return;
    }
    state = const ShopManagementLoading();
    try {
      await _repo.approveShop(shopId, adminUid);
      state = const ShopManagementSuccess('Shop approved.');
    } catch (e) {
      state = ShopManagementError(e.toString());
    }
  }

  Future<void> reject(String shopId, String reason) async {
    state = const ShopManagementLoading();
    try {
      await _repo.rejectShop(shopId, reason);
      state = const ShopManagementSuccess('Shop rejected.');
    } catch (e) {
      state = ShopManagementError(e.toString());
    }
  }

  Future<void> suspend(String shopId, String reason) async {
    state = const ShopManagementLoading();
    try {
      await _repo.suspendShop(shopId, reason);
      state = const ShopManagementSuccess('Shop suspended.');
    } catch (e) {
      state = ShopManagementError(e.toString());
    }
  }

  void reset() => state = const ShopManagementIdle();
}

final shopManagementProvider =
    NotifierProvider<ShopManagementNotifier, ShopManagementState>(
  ShopManagementNotifier.new,
);
