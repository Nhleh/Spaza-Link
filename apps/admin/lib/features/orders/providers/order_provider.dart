import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';

import '../data/firebase_order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return AdminFirebaseOrderRepository();
});

/// All orders paginated (admin view). Refresh to reload.
final adminOrdersProvider =
    FutureProvider.family<List<OrderModel>, String?>((ref, status) {
  return ref.read(orderRepositoryProvider).getOrdersForAdmin(status: status);
});

final adminOrderDetailProvider =
    FutureProvider.family<OrderModel?, String>((ref, orderId) {
  return ref.read(orderRepositoryProvider).getOrder(orderId);
});

// ── Order status update notifier ──────────────────────────────────────────────

sealed class OrderActionState {}

class OrderActionIdle extends OrderActionState {}

class OrderActionLoading extends OrderActionState {}

class OrderActionSuccess extends OrderActionState {}

class OrderActionError extends OrderActionState {
  OrderActionError(this.message);
  final String message;
}

class OrderActionNotifier extends Notifier<OrderActionState> {
  @override
  OrderActionState build() => OrderActionIdle();

  OrderRepository get _repo => ref.read(orderRepositoryProvider);

  Future<void> updateStatus({
    required String orderId,
    required String status,
    String? adminId,
  }) async {
    state = OrderActionLoading();
    try {
      await _repo.updateOrderStatus(
        orderId: orderId,
        status: status,
        adminId: adminId,
      );
      state = OrderActionSuccess();
    } catch (e) {
      state = OrderActionError(e.toString());
    }
  }

  Future<void> cancel(String orderId) async {
    state = OrderActionLoading();
    try {
      await _repo.cancelOrder(orderId);
      state = OrderActionSuccess();
    } catch (e) {
      state = OrderActionError(e.toString());
    }
  }

  void reset() => state = OrderActionIdle();
}

final orderActionProvider =
    NotifierProvider<OrderActionNotifier, OrderActionState>(
        OrderActionNotifier.new);
