import '../models/order_model.dart';

abstract interface class OrderRepository {
  /// Real-time stream of orders for the given shop (customer-facing).
  Stream<List<OrderModel>> watchOrders({required String shopId});

  Future<List<OrderModel>> getOrders({
    required String shopId,
    int limit = 20,
    String? startAfterId,
  });

  Future<OrderModel?> getOrder(String orderId);

  /// Persists a new order to Firestore. Returns the saved order with server ID.
  Future<OrderModel> placeOrder(OrderModel order);

  Future<void> cancelOrder(String orderId);

  // ── Admin ──────────────────────────────────────────────────────────────────

  /// All orders across shops, optionally filtered by [status].
  Future<List<OrderModel>> getOrdersForAdmin({
    String? status,
    int limit = 50,
    String? startAfterId,
  });

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
    String? adminId,
  });

  // ── Offline queue (Hive) ──────────────────────────────────────────────────

  Future<void> savePendingOrder(OrderModel order);
  Future<List<OrderModel>> getPendingOrders();
  Future<void> removePendingOrder(String localUuid);
}
