import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';
import 'package:uuid/uuid.dart';

import '../data/supabase_order_repository.dart';
import '../../cart/providers/cart_provider.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return SupabaseOrderRepository();
});

/// Live orders stream for the active shop.
final shopOrdersProvider =
    StreamProvider.family<List<OrderModel>, String>((ref, shopId) {
  return ref.watch(orderRepositoryProvider).watchOrders(shopId: shopId);
});

final singleOrderProvider =
    FutureProvider.family<OrderModel?, String>((ref, orderId) {
  return ref.watch(orderRepositoryProvider).getOrder(orderId);
});

// ── Place order notifier ──────────────────────────────────────────────────

sealed class PlaceOrderState {}

class PlaceOrderIdle extends PlaceOrderState {}

class PlaceOrderLoading extends PlaceOrderState {}

class PlaceOrderSuccess extends PlaceOrderState {
  PlaceOrderSuccess(this.order);
  final OrderModel order;
}

class PlaceOrderError extends PlaceOrderState {
  PlaceOrderError(this.message);
  final String message;
}

class PlaceOrderNotifier extends Notifier<PlaceOrderState> {
  static const _uuid = Uuid();

  @override
  PlaceOrderState build() => PlaceOrderIdle();

  Future<void> place({
    required String shopId,
    required String customerId,
    required String deliveryAddress,
    required String paymentMethod,
    String? notes,
    DateTime? scheduledDeliveryDate,
  }) async {
    state = PlaceOrderLoading();

    final repo = ref.read(orderRepositoryProvider);
    final cartRepo = ref.read(cartRepositoryProvider);

    try {
      final items = await cartRepo.getItems(shopId);
      if (items.isEmpty) {
        state = PlaceOrderError('Your cart is empty.');
        return;
      }

      final orderItems = items
          .map((c) => OrderItemModel(
                productId: c.productId,
                productName: c.productName,
                imageUrl: c.imageUrl,
                packSize: c.packSize,
                quantity: c.quantity,
                unitPriceCents: c.effectivePriceCents,
                lineTotalCents: c.lineTotalCents,
              ))
          .toList();

      final subtotal = orderItems.fold(0, (s, i) => s + i.lineTotalCents);
      final fee = subtotal >= AppConstants.freeDeliveryThresholdCents
          ? 0
          : AppConstants.deliveryFeeCents;
      final total = subtotal + fee;

      final order = OrderModel(
        localUuid: _uuid.v4(),
        shopId: shopId,
        customerId: customerId,
        items: orderItems,
        subtotalCents: subtotal,
        deliveryFeeCents: fee,
        totalCents: total,
        deliveryAddress: deliveryAddress,
        notes: notes,
        paymentMethod: paymentMethod,
        syncStatus: SyncStatus.local,
        scheduledDeliveryDate: scheduledDeliveryDate,
        placedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      OrderModel saved;
      try {
        saved = await repo.placeOrder(order);
      } catch (_) {
        // Offline — queue locally.
        await repo.savePendingOrder(order);
        saved = order;
      }

      await cartRepo.clearCart(shopId);
      state = PlaceOrderSuccess(saved);
    } catch (e) {
      state = PlaceOrderError(e.toString());
    }
  }

  void reset() => state = PlaceOrderIdle();
}

final placeOrderProvider =
    NotifierProvider<PlaceOrderNotifier, PlaceOrderState>(
        PlaceOrderNotifier.new);
