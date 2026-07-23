import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  // HiveCartRepository.create() is async; call initHive() in main.dart first.
  // At provider creation time Hive is already open, so we open the box inline.
  throw UnimplementedError(
    'cartRepositoryProvider must be overridden in ProviderScope with '
    'the HiveCartRepository instance created in main.dart.',
  );
});

/// Stream of cart items scoped to the active shop.
final cartItemsProvider =
    StreamProvider.family<List<CartItemModel>, String>((ref, shopId) {
  return ref.watch(cartRepositoryProvider).watchItems(shopId);
});

/// Derived: total number of items (sum of quantities) in the cart.
final cartItemCountProvider =
    Provider.family<int, String>((ref, shopId) {
  final items = ref.watch(cartItemsProvider(shopId)).valueOrNull ?? [];
  return items.fold(0, (sum, item) => sum + item.quantity);
});

/// Derived: subtotal in cents.
final cartSubtotalProvider =
    Provider.family<int, String>((ref, shopId) {
  final items = ref.watch(cartItemsProvider(shopId)).valueOrNull ?? [];
  return items.fold(0, (sum, item) => sum + item.lineTotalCents);
});

/// Derived: delivery fee based on subtotal (business rule: R135 under R1750, free above).
final cartDeliveryFeeProvider =
    Provider.family<int, String>((ref, shopId) {
  final subtotal = ref.watch(cartSubtotalProvider(shopId));
  return subtotal >= AppConstants.freeDeliveryThresholdCents
      ? 0
      : AppConstants.deliveryFeeCents;
});

/// Derived: order total in cents.
final cartTotalProvider =
    Provider.family<int, String>((ref, shopId) {
  final subtotal = ref.watch(cartSubtotalProvider(shopId));
  final fee = ref.watch(cartDeliveryFeeProvider(shopId));
  return subtotal + fee;
});

/// Derived: whether the minimum order amount has been met.
final meetsMinOrderProvider =
    Provider.family<bool, String>((ref, shopId) {
  return ref.watch(cartSubtotalProvider(shopId)) >=
      AppConstants.minOrderCents;
});

// ── Cart actions notifier ──────────────────────────────────────────────────

class CartNotifier extends Notifier<void> {
  @override
  void build() {}

  CartRepository get _repo => ref.read(cartRepositoryProvider);

  Future<void> addItem(CartItemModel item) => _repo.upsertItem(item);

  Future<void> updateQuantity({
    required String productId,
    required String shopId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      await _repo.removeItem(productId: productId, shopId: shopId);
      return;
    }
    final items = await _repo.getItems(shopId);
    final existing = items.where((i) => i.productId == productId).firstOrNull;
    if (existing != null) {
      await _repo.upsertItem(existing.copyWith(quantity: quantity));
    }
  }

  Future<void> removeItem({
    required String productId,
    required String shopId,
  }) =>
      _repo.removeItem(productId: productId, shopId: shopId);

  Future<void> clearCart(String shopId) => _repo.clearCart(shopId);
}

final cartNotifierProvider = NotifierProvider<CartNotifier, void>(CartNotifier.new);
