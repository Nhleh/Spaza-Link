import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spazalink_core/core.dart';

/// Admin order repository — read-only for customer orders, full write for status.
/// Does not implement offline queue (admin dashboard is always online).
class AdminFirebaseOrderRepository implements OrderRepository {
  AdminFirebaseOrderRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreConstants.colOrders);

  @override
  Stream<List<OrderModel>> watchOrders({required String shopId}) {
    return _col
        .where(FirestoreConstants.fldShopId, isEqualTo: shopId)
        .orderBy(FirestoreConstants.fldCreatedAt, descending: true)
        .snapshots()
        .map((s) => s.docs.map(_fromDoc).toList());
  }

  @override
  Future<List<OrderModel>> getOrders({
    required String shopId,
    int limit = 20,
    String? startAfterId,
  }) async {
    Query<Map<String, dynamic>> q = _col
        .where(FirestoreConstants.fldShopId, isEqualTo: shopId)
        .orderBy(FirestoreConstants.fldCreatedAt, descending: true)
        .limit(limit);
    if (startAfterId != null) {
      final cursor = await _col.doc(startAfterId).get();
      if (cursor.exists) q = q.startAfterDocument(cursor);
    }
    return (await q.get()).docs.map(_fromDoc).toList();
  }

  @override
  Future<OrderModel?> getOrder(String orderId) async {
    final doc = await _col.doc(orderId).get();
    if (!doc.exists || doc.data() == null) return null;
    return _fromDoc(doc);
  }

  @override
  Future<List<OrderModel>> getOrdersForAdmin({
    String? status,
    int limit = 50,
    String? startAfterId,
  }) async {
    Query<Map<String, dynamic>> q =
        _col.orderBy(FirestoreConstants.fldCreatedAt, descending: true).limit(limit);
    if (status != null) q = q.where(FirestoreConstants.fldStatus, isEqualTo: status);
    if (startAfterId != null) {
      final cursor = await _col.doc(startAfterId).get();
      if (cursor.exists) q = q.startAfterDocument(cursor);
    }
    return (await q.get()).docs.map(_fromDoc).toList();
  }

  @override
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
    String? adminId,
  }) {
    return _col.doc(orderId).update({
      FirestoreConstants.fldStatus: status,
      FirestoreConstants.fldUpdatedAt: Timestamp.fromDate(DateTime.now()),
      if (adminId != null) 'processedBy': adminId,
    });
  }

  // Admin dashboard doesn't place or cancel orders via the app.
  @override
  Future<OrderModel> placeOrder(OrderModel order) =>
      throw UnsupportedError('Admin cannot place orders.');

  @override
  Future<void> cancelOrder(String orderId) {
    return updateOrderStatus(orderId: orderId, status: OrderStatus.cancelled);
  }

  // No offline queue for admin.
  @override
  Future<void> savePendingOrder(OrderModel order) async {}
  @override
  Future<List<OrderModel>> getPendingOrders() async => [];
  @override
  Future<void> removePendingOrder(String localUuid) async {}

  // ── Helpers ────────────────────────────────────────────────────────────────

  OrderModel _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final rawItems = d['items'] as List<dynamic>? ?? [];
    return OrderModel(
      id: doc.id,
      localUuid: (d['localUuid'] as String?) ?? doc.id,
      orderNumber: (d['orderNumber'] as String?) ?? '',
      shopId: (d[FirestoreConstants.fldShopId] as String?) ?? '',
      customerId: (d['customerId'] as String?) ?? '',
      status: (d[FirestoreConstants.fldStatus] as String?) ?? OrderStatus.pending,
      syncStatus: SyncStatus.synced,
      items: rawItems
          .map((i) => OrderItemModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      subtotalCents: (d['subtotalCents'] as int?) ?? 0,
      deliveryFeeCents: (d['deliveryFeeCents'] as int?) ?? 0,
      discountAmountCents: (d['discountAmountCents'] as int?) ?? 0,
      totalCents: (d['totalCents'] as int?) ?? 0,
      deliveryAddress: (d['deliveryAddress'] as String?) ?? '',
      notes: d['notes'] as String?,
      paymentMethod: (d['paymentMethod'] as String?) ?? PaymentMethod.cod,
      paymentStatus: (d['paymentStatus'] as String?) ?? PaymentStatus.pending,
      scheduledDeliveryDate: _tsNull(d['scheduledDeliveryDate']),
      driverId: d['driverId'] as String?,
      deliveryId: d['deliveryId'] as String?,
      placedAt: _ts(d['placedAt'] ?? d[FirestoreConstants.fldCreatedAt]),
      createdAt: _ts(d[FirestoreConstants.fldCreatedAt]),
      updatedAt: _ts(d[FirestoreConstants.fldUpdatedAt]),
    );
  }

  DateTime _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return DateTime.now();
  }

  DateTime? _tsNull(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }
}
