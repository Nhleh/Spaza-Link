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

/// Statuses that mean an order is confirmed and still on its way (spec #13):
/// excludes pending (not yet confirmed), delivered and cancelled.
const Set<String> kAwaitingDeliveryStatuses = {
  OrderStatus.confirmed,
  OrderStatus.preparing,
  OrderStatus.outForDelivery,
};

/// Expected delivery time — within 18 hours of the order being confirmed
/// (spec #12). We use [OrderModel.updatedAt] (the time the status last changed,
/// i.e. to confirmed) as the confirmation reference the backend records.
DateTime deliveryEta(OrderModel order) =>
    order.updatedAt.add(const Duration(hours: 18));

/// The order whose delivery is next up for [shopId]: a confirmed order still
/// awaiting delivery, choosing the soonest expected delivery when there are
/// several (spec #14). Null when nothing is on the way — the card then shows
/// "No Delivery" and never a completed/cancelled order (spec #13).
final nextDeliveryProvider =
    Provider.family<OrderModel?, String>((ref, shopId) {
  if (shopId.isEmpty) return null;
  final orders = ref.watch(shopOrdersProvider(shopId)).valueOrNull ?? const [];
  final active =
      orders.where((o) => kAwaitingDeliveryStatuses.contains(o.status)).toList();
  if (active.isEmpty) return null;
  active.sort((a, b) => deliveryEta(a).compareTo(deliveryEta(b)));
  return active.first;
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

      // Special-discount savings: what the on-sale items saved vs full price.
      final discountSaved = items.fold<int>(0, (s, c) {
        final sale = c.salePriceCents;
        return (sale != null && sale < c.priceCents)
            ? s + (c.priceCents - sale) * c.quantity
            : s;
      });

      final order = OrderModel(
        localUuid: _uuid.v4(),
        shopId: shopId,
        customerId: customerId,
        items: orderItems,
        subtotalCents: subtotal,
        deliveryFeeCents: fee,
        discountAmountCents: discountSaved,
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
      // Refresh the (one-shot) orders stream so the new order shows on the
      // Orders tab immediately.
      ref.invalidate(shopOrdersProvider);
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
