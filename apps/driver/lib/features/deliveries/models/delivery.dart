/// A delivery job as the driver sees it (an order assigned to them).
class Delivery {
  const Delivery({
    required this.orderId,
    required this.status,
    required this.totalCents,
    required this.placedAt,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.items,
    required this.shopName,
    required this.customerName,
    this.deliveredAt,
  });

  final String orderId;
  final String status;
  final int totalCents;
  final DateTime placedAt;
  final String pickupAddress;
  final String deliveryAddress;
  final String paymentMethod;
  final String paymentStatus;
  final List<DeliveryItem> items;
  final String shopName;
  final String customerName;
  final DateTime? deliveredAt;

  String get ref => orderId.split('-').first.toUpperCase();
  bool get isAssigned => status == 'assigned';
  bool get isOutForDelivery => status == 'out_for_delivery';
  bool get isCod => paymentMethod == 'cod';

  /// Where the driver needs to go right now.
  String get currentTargetAddress => isAssigned ? pickupAddress : deliveryAddress;
  String get currentTargetLabel => isAssigned ? 'Pickup' : 'Delivery';

  factory Delivery.fromRow(Map<String, dynamic> r) {
    final itemRows = (r['order_items'] as List?) ?? const [];
    final shop = r['shops'];
    return Delivery(
      orderId: r['id'] as String? ?? '',
      status: r['status'] as String? ?? 'assigned',
      totalCents: (r['total_cents'] as num?)?.toInt() ?? 0,
      placedAt: DateTime.tryParse('${r['created_at']}')?.toLocal() ?? DateTime.now(),
      pickupAddress: (r['pickup_address'] as String? ?? '').trim(),
      deliveryAddress: (r['delivery_address'] as String? ?? '').trim(),
      paymentMethod: r['payment_method'] as String? ?? 'cod',
      paymentStatus: r['payment_status'] as String? ?? 'pending',
      shopName: shop is Map ? (shop['shop_name'] as String? ?? '') : '',
      customerName: shop is Map ? (shop['owner_name'] as String? ?? '') : '',
      deliveredAt: DateTime.tryParse('${r['delivered_at']}')?.toLocal(),
      items: itemRows
          .map((i) => DeliveryItem.fromRow(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DeliveryItem {
  const DeliveryItem({
    required this.name,
    required this.qty,
    required this.priceCents,
  });

  final String name;
  final int qty;
  final int priceCents;

  int get lineTotalCents => qty * priceCents;

  factory DeliveryItem.fromRow(Map<String, dynamic> r) => DeliveryItem(
        name: r['name'] as String? ?? '',
        qty: (r['qty'] as num?)?.toInt() ?? 1,
        priceCents: (r['price_cents'] as num?)?.toInt() ?? 0,
      );
}
