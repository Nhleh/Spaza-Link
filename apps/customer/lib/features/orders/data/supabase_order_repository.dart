import 'package:spazalink_core/core.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

/// Supabase-backed order repository for the Customer app. Places orders into the
/// same `orders`/`order_items` tables the Admin reads, so a customer order shows
/// up on the admin dashboard immediately. RLS lets a customer insert/read only
/// their own orders (customer_id = auth.uid()).
class SupabaseOrderRepository implements OrderRepository {
  SupabaseOrderRepository({supa.SupabaseClient? client})
      : _sb = client ?? supa.Supabase.instance.client;

  final supa.SupabaseClient _sb;

  static const _orders = 'orders';
  static const _items = 'order_items';

  @override
  Future<OrderModel> placeOrder(OrderModel order) async {
    final row = await _sb
        .from(_orders)
        .insert({
          'customer_id': order.customerId,
          'shop_id': order.shopId.isEmpty ? null : order.shopId,
          'status': order.status,
          'total_cents': order.totalCents,
          'local_uuid': order.localUuid,
        })
        .select()
        .single();
    final orderId = row['id'] as String;
    if (order.items.isNotEmpty) {
      await _sb.from(_items).insert([
        for (final it in order.items)
          {
            'order_id': orderId,
            'product_id': it.productId.isEmpty ? null : it.productId,
            'name': it.productName,
            'qty': it.quantity,
            'price_cents': it.unitPriceCents,
          }
      ]);
    }
    return _fromRow(row, items: order.items);
  }

  @override
  Stream<List<OrderModel>> watchOrders({required String shopId}) async* {
    final rows = await _sb
        .from(_orders)
        .select()
        .eq('shop_id', shopId)
        .order('created_at', ascending: false);
    yield (rows as List)
        .map((r) => _fromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<OrderModel>> getOrders({
    required String shopId,
    int limit = 20,
    String? startAfterId,
  }) async {
    final rows = await _sb
        .from(_orders)
        .select()
        .eq('shop_id', shopId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((r) => _fromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<OrderModel?> getOrder(String orderId) async {
    final row =
        await _sb.from(_orders).select().eq('id', orderId).maybeSingle();
    if (row == null) return null;
    final itemRows = await _sb.from(_items).select().eq('order_id', orderId);
    final items = (itemRows as List)
        .map((i) => _itemFromRow(i as Map<String, dynamic>))
        .toList();
    return _fromRow(row, items: items);
  }

  @override
  Future<void> cancelOrder(String orderId) async {
    await _sb.from(_orders).update({
      'status': OrderStatus.cancelled,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }

  // ── Admin-only / offline queue: not used on the customer online path ─────────
  @override
  Future<List<OrderModel>> getOrdersForAdmin({
    String? status,
    int limit = 50,
    String? startAfterId,
  }) async =>
      [];

  @override
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
    String? adminId,
  }) async {
    await _sb.from(_orders).update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }

  @override
  Future<void> savePendingOrder(OrderModel order) async {}
  @override
  Future<List<OrderModel>> getPendingOrders() async => [];
  @override
  Future<void> removePendingOrder(String localUuid) async {}

  // ── Mapping ──────────────────────────────────────────────────────────────────
  OrderModel _fromRow(Map<String, dynamic> r, {List<OrderItemModel>? items}) {
    final total = (r['total_cents'] as num?)?.toInt() ?? 0;
    final created = _parseDt(r['created_at']);
    return OrderModel(
      id: r['id'] as String? ?? '',
      localUuid: r['local_uuid'] as String? ?? '',
      orderNumber: (r['id'] as String? ?? '').split('-').first.toUpperCase(),
      shopId: r['shop_id'] as String? ?? '',
      customerId: r['customer_id'] as String? ?? '',
      status: r['status'] as String? ?? OrderStatus.pending,
      items: items ?? const [],
      subtotalCents: total,
      deliveryFeeCents: 0,
      totalCents: total,
      deliveryAddress: '',
      driverId: r['driver_id'] as String?,
      placedAt: created,
      createdAt: created,
      updatedAt: _parseDt(r['updated_at']),
    );
  }

  OrderItemModel _itemFromRow(Map<String, dynamic> r) {
    final qty = (r['qty'] as num?)?.toInt() ?? 1;
    final price = (r['price_cents'] as num?)?.toInt() ?? 0;
    return OrderItemModel(
      productId: r['product_id'] as String? ?? '',
      productName: r['name'] as String? ?? '',
      quantity: qty,
      unitPriceCents: price,
      lineTotalCents: qty * price,
    );
  }

  DateTime _parseDt(dynamic v) => v == null
      ? DateTime.now()
      : DateTime.tryParse(v.toString()) ?? DateTime.now();
}
