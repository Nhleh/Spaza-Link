import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spazalink_core/core.dart';

class FirebaseDeliveryRepository implements DeliveryRepository {
  FirebaseDeliveryRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreConstants.colDeliveries);

  @override
  Stream<List<DeliveryModel>> watchAssignedDeliveries(String driverId) {
    return _col
        .where(FirestoreConstants.fldDriverId, isEqualTo: driverId)
        .where(
          FirestoreConstants.fldDeliveryStatus,
          whereIn: [DeliveryStatus.assigned, DeliveryStatus.enRoute, DeliveryStatus.arrived],
        )
        .orderBy(FirestoreConstants.fldAssignedAt, descending: true)
        .snapshots()
        .map((s) => s.docs.map(_fromDoc).toList());
  }

  @override
  Future<DeliveryModel?> getDelivery(String deliveryId) async {
    final doc = await _col.doc(deliveryId).get();
    if (!doc.exists || doc.data() == null) return null;
    return _fromDoc(doc);
  }

  @override
  Future<void> updateDeliveryStatus({
    required String deliveryId,
    required String status,
    String? proofPhotoUrl,
    String? signatureUrl,
  }) {
    return _col.doc(deliveryId).update({
      FirestoreConstants.fldDeliveryStatus: status,
      if (proofPhotoUrl != null)
        FirestoreConstants.fldProofPhotoUrl: proofPhotoUrl,
      if (signatureUrl != null) FirestoreConstants.fldSignatureUrl: signatureUrl,
      if (status == DeliveryStatus.delivered)
        FirestoreConstants.fldDeliveredAt: Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Future<void> updateDriverLocation({
    required String driverId,
    required GpsLocation location,
  }) {
    return _db
        .collection(FirestoreConstants.colDrivers)
        .doc(driverId)
        .update({
      FirestoreConstants.fldCurrentLocation:
          GeoPoint(location.latitude, location.longitude),
    });
  }

  @override
  Future<DeliveryModel> assignDelivery({
    required String orderId,
    required String shopId,
    required String driverId,
    required String deliveryAddress,
  }) async {
    final ref = _col.doc();
    final now = DateTime.now();
    final delivery = DeliveryModel(
      id: ref.id,
      orderId: orderId,
      driverId: driverId,
      shopId: shopId,
      deliveryAddress: deliveryAddress,
      status: DeliveryStatus.assigned,
      assignedAt: now,
    );
    await ref.set(_toMap(delivery));

    // Link delivery back to order.
    await _db.collection(FirestoreConstants.colOrders).doc(orderId).update({
      FirestoreConstants.fldDriverId: driverId,
      FirestoreConstants.fldDeliveryId: ref.id,
      FirestoreConstants.fldStatus: OrderStatus.outForDelivery,
      FirestoreConstants.fldUpdatedAt: Timestamp.fromDate(now),
    });

    return delivery;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  DeliveryModel _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    GpsLocation? loc;
    final rawLoc = d['currentLocation'];
    if (rawLoc is GeoPoint) {
      loc = GpsLocation(latitude: rawLoc.latitude, longitude: rawLoc.longitude);
    }
    return DeliveryModel(
      id: doc.id,
      orderId: (d['orderId'] as String?) ?? '',
      driverId: (d[FirestoreConstants.fldDriverId] as String?) ?? '',
      shopId: (d[FirestoreConstants.fldShopId] as String?) ?? '',
      deliveryAddress: (d['deliveryAddress'] as String?) ?? '',
      status: (d[FirestoreConstants.fldDeliveryStatus] as String?) ??
          DeliveryStatus.assigned,
      estimatedArrival: _tsNull(d[FirestoreConstants.fldEstimatedArrival]),
      proofPhotoUrl: d[FirestoreConstants.fldProofPhotoUrl] as String?,
      signatureUrl: d[FirestoreConstants.fldSignatureUrl] as String?,
      deliveredAt: _tsNull(d[FirestoreConstants.fldDeliveredAt]),
      assignedAt: _ts(d[FirestoreConstants.fldAssignedAt]),
      notes: d['notes'] as String?,
      currentLocation: loc,
    );
  }

  Map<String, dynamic> _toMap(DeliveryModel d) => {
        'orderId': d.orderId,
        FirestoreConstants.fldDriverId: d.driverId,
        FirestoreConstants.fldShopId: d.shopId,
        'deliveryAddress': d.deliveryAddress,
        FirestoreConstants.fldDeliveryStatus: d.status,
        FirestoreConstants.fldEstimatedArrival: d.estimatedArrival != null
            ? Timestamp.fromDate(d.estimatedArrival!)
            : null,
        FirestoreConstants.fldAssignedAt: Timestamp.fromDate(d.assignedAt),
        'notes': d.notes,
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
