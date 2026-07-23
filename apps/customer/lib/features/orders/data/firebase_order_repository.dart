import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:spazalink_core/core.dart';

class FirebaseOrderRepository implements OrderRepository {
  static const _pendingBoxName = 'pending_orders';

  FirebaseOrderRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreConstants.colOrders);

  // ── Customer ───────────────────────────────────────────────────────────────

  @override
  Stream<List<OrderModel>> watchOrders({required String shopId}) {
    return _col
        .where(FirestoreConstants.fldShopId, isEqualTo: shopId)
        .orderBy(FirestoreConstants.fldCreatedAt, descending: true)
        .limit(50)
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
    final snap = await q.get();
    return snap.docs.map(_fromDoc).toList();
  }

  @override
  Future<OrderModel?> getOrder(String orderId) async {
    final doc = await _col.doc(orderId).get();
    if (!doc.exists || doc.data() == null) return null;
    return _fromDoc(doc);
  }

  @override
  Future<OrderModel> placeOrder(OrderModel order) async {
    final ref = _col.doc();
    final now = DateTime.now();
    final saved = order.copyWith(
      id: ref.id,
      syncStatus: SyncStatus.synced,
      createdAt: now,
      updatedAt: now,
      placedAt: now,
    );
    await ref.set(_toMap(saved));
    return saved;
  }

  @override
  Future<void> cancelOrder(String orderId) {
    return _col.doc(orderId).update({
      FirestoreConstants.fldStatus: OrderStatus.cancelled,
      FirestoreConstants.fldUpdatedAt: Timestamp.fromDate(DateTime.now()),
    });
  }

  // ── Admin ──────────────────────────────────────────────────────────────────

  @override
  Future<List<OrderModel>> getOrdersForAdmin({
    String? status,
    int limit = 50,
    String? startAfterId,
  }) async {
    Query<Map<String, dynamic>> q =
        _col.orderBy(FirestoreConstants.fldCreatedAt, descending: true).limit(limit);
    if (status != null) {
      q = q.where(FirestoreConstants.fldStatus, isEqualTo: status);
    }
    if (startAfterId != null) {
      final cursor = await _col.doc(startAfterId).get();
      if (cursor.exists) q = q.startAfterDocument(cursor);
    }
    final snap = await q.get();
    return snap.docs.map(_fromDoc).toList();
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

  // ── Offline queue (Hive) ──────────────────────────────────────────────────

  Future<Box<String>> get _pendingBox =>
      Hive.openBox<String>(_pendingBoxName);

  @override
  Future<void> savePendingOrder(OrderModel order) async {
    final box = await _pendingBox;
    await box.put(order.localUuid, jsonEncode(order.toJson()));
  }

  @override
  Future<List<OrderModel>> getPendingOrders() async {
    final box = await _pendingBox;
    return box.values.map((raw) {
      return OrderModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }).toList();
  }

  @override
  Future<void> removePendingOrder(String localUuid) async {
    final box = await _pendingBox;
    await box.delete(localUuid);
  }

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
      placedAt: _ts(d['placedAt']),
      createdAt: _ts(d[FirestoreConstants.fldCreatedAt]),
      updatedAt: _ts(d[FirestoreConstants.fldUpdatedAt]),
    );
  }

  Map<String, dynamic> _toMap(OrderModel o) => {
        'localUuid': o.localUuid,
        'orderNumber': o.orderNumber,
        FirestoreConstants.fldShopId: o.shopId,
        'customerId': o.customerId,
        FirestoreConstants.fldStatus: o.status,
        'items': o.items.map((i) => _itemToMap(i)).toList(),
        'subtotalCents': o.subtotalCents,
        'deliveryFeeCents': o.deliveryFeeCents,
        'discountAmountCents': o.discountAmountCents,
        'totalCents': o.totalCents,
        'deliveryAddress': o.deliveryAddress,
        'notes': o.notes,
        'paymentMethod': o.paymentMethod,
        'paymentStatus': o.paymentStatus,
        'scheduledDeliveryDate': o.scheduledDeliveryDate != null
            ? Timestamp.fromDate(o.scheduledDeliveryDate!)
            : null,
        'driverId': o.driverId,
        'deliveryId': o.deliveryId,
        'placedAt': Timestamp.fromDate(o.placedAt),
        FirestoreConstants.fldCreatedAt: Timestamp.fromDate(o.createdAt),
        FirestoreConstants.fldUpdatedAt: Timestamp.fromDate(o.updatedAt),
      };

  Map<String, dynamic> _itemToMap(OrderItemModel i) => {
        'productId': i.productId,
        'productName': i.productName,
        'imageUrl': i.imageUrl,
        'sku': i.sku,
        'packSize': i.packSize,
        'quantity': i.quantity,
        'unitPriceCents': i.unitPriceCents,
        'lineTotalCents': i.lineTotalCents,
      };

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
