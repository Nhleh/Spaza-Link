import 'package:flutter_test/flutter_test.dart';
import 'package:spazalink_core/core.dart';

void main() {
  final _now = DateTime(2026, 1, 15, 10, 30);

  OrderModel _makeOrder({
    String status = OrderStatus.pending,
    String syncStatus = SyncStatus.local,
    int subtotalCents = 100000,
    int deliveryFeeCents = 13500,
    int discountAmountCents = 0,
    String paymentStatus = PaymentStatus.pending,
  }) =>
      OrderModel(
        localUuid: 'local-uuid-001',
        shopId: 'shop-1',
        customerId: 'cust-1',
        status: status,
        syncStatus: syncStatus,
        items: const [],
        subtotalCents: subtotalCents,
        deliveryFeeCents: deliveryFeeCents,
        discountAmountCents: discountAmountCents,
        totalCents: subtotalCents + deliveryFeeCents - discountAmountCents,
        deliveryAddress: '5 Main St, Soweto, 1804',
        paymentMethod: PaymentMethod.cod,
        paymentStatus: paymentStatus,
        placedAt: _now,
        createdAt: _now,
        updatedAt: _now,
      );

  group('OrderModel.fromJson / toJson', () {
    test('round-trips without data loss', () {
      final original = _makeOrder(
        status: OrderStatus.confirmed,
        syncStatus: SyncStatus.synced,
        subtotalCents: 175000,
        deliveryFeeCents: 0,
        discountAmountCents: 5000,
        paymentStatus: PaymentStatus.paid,
      ).copyWith(
        id: 'firestore-id-abc',
        orderNumber: 'SL-00042',
      );
      final json = original.toJson();
      final restored = OrderModel.fromJson(json);
      expect(restored, original);
    });

    test('int timestamp is parsed correctly', () {
      final ts = _now.millisecondsSinceEpoch;
      final order = OrderModel.fromJson({
        'localUuid': 'uuid-1',
        'shopId': 's1',
        'customerId': 'c1',
        'subtotalCents': 50000,
        'deliveryFeeCents': 13500,
        'totalCents': 63500,
        'deliveryAddress': 'addr',
        'placedAt': ts,
        'createdAt': ts,
        'updatedAt': ts,
      });
      expect(order.placedAt, _now);
      expect(order.createdAt, _now);
    });

    test('default status is pending', () {
      final order = _makeOrder();
      expect(order.status, OrderStatus.pending);
    });

    test('default payment method is COD', () {
      final order = _makeOrder();
      expect(order.paymentMethod, PaymentMethod.cod);
    });
  });

  group('OrderStatus constants', () {
    test('all status strings are defined', () {
      expect(OrderStatus.pending, 'pending');
      expect(OrderStatus.confirmed, 'confirmed');
      expect(OrderStatus.preparing, 'preparing');
      expect(OrderStatus.outForDelivery, 'out_for_delivery');
      expect(OrderStatus.delivered, 'delivered');
      expect(OrderStatus.cancelled, 'cancelled');
    });
  });

  group('SyncStatus constants', () {
    test('all sync states are defined', () {
      expect(SyncStatus.local, 'local');
      expect(SyncStatus.syncing, 'syncing');
      expect(SyncStatus.synced, 'synced');
      expect(SyncStatus.failed, 'failed');
    });
  });
}
