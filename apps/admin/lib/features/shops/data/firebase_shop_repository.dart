import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spazalink_core/core.dart';

/// Admin-side repository for reviewing and approving shops.
class FirebaseShopRepository {
  FirebaseShopRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreConstants.colShops);

  /// Streams shops, optionally filtered by [status] (pending/approved/…).
  Stream<List<ShopModel>> watchShops({String? status}) {
    Query<Map<String, dynamic>> q = _col;
    if (status != null) {
      q = q.where(FirestoreConstants.fldStatus, isEqualTo: status);
    }
    return q.snapshots().map(
          (s) => s.docs.map((d) => _fromMap(d.id, d.data())).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  /// Approves a shop — sets status=approved and records who/when.
  Future<void> approveShop(String shopId, String adminUid) {
    return _col.doc(shopId).update({
      FirestoreConstants.fldStatus: AppConstants.shopStatusApproved,
      FirestoreConstants.fldApprovedBy: adminUid,
      FirestoreConstants.fldApprovedAt: Timestamp.fromDate(DateTime.now()),
      FirestoreConstants.fldRejectionReason: null,
      FirestoreConstants.fldUpdatedAt: Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Rejects a shop with a [reason].
  Future<void> rejectShop(String shopId, String reason) {
    return _col.doc(shopId).update({
      FirestoreConstants.fldStatus: AppConstants.shopStatusRejected,
      FirestoreConstants.fldRejectionReason: reason,
      FirestoreConstants.fldUpdatedAt: Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Suspends a previously-approved shop.
  Future<void> suspendShop(String shopId, String reason) {
    return _col.doc(shopId).update({
      FirestoreConstants.fldStatus: AppConstants.shopStatusSuspended,
      FirestoreConstants.fldRejectionReason: reason,
      FirestoreConstants.fldUpdatedAt: Timestamp.fromDate(DateTime.now()),
    });
  }

  ShopModel _fromMap(String id, Map<String, dynamic> d) {
    GpsLocation? gps;
    final raw = d['gpsLocation'];
    if (raw is GeoPoint) {
      gps = GpsLocation(latitude: raw.latitude, longitude: raw.longitude);
    } else if (raw is Map) {
      gps = GpsLocation(
        latitude: (raw['latitude'] as num).toDouble(),
        longitude: (raw['longitude'] as num).toDouble(),
      );
    }
    return ShopModel(
      id: id,
      ownerId: (d[FirestoreConstants.fldOwnerId] as String?) ?? '',
      shopName: (d[FirestoreConstants.fldShopName] as String?) ?? '',
      ownerName: (d[FirestoreConstants.fldOwnerName] as String?) ?? '',
      physicalAddress:
          (d[FirestoreConstants.fldPhysicalAddress] as String?) ?? '',
      city: (d['city'] as String?) ?? '',
      province: (d['province'] as String?) ?? '',
      gpsLocation: gps,
      status: (d[FirestoreConstants.fldStatus] as String?) ??
          AppConstants.shopStatusPending,
      rejectionReason: d[FirestoreConstants.fldRejectionReason] as String?,
      approvedBy: d[FirestoreConstants.fldApprovedBy] as String?,
      approvedAt: d[FirestoreConstants.fldApprovedAt] is Timestamp
          ? (d[FirestoreConstants.fldApprovedAt] as Timestamp).toDate()
          : null,
      shopPhotoUrl: d[FirestoreConstants.fldShopPhotoUrl] as String?,
      businessRegUrl: d[FirestoreConstants.fldBusinessRegUrl] as String?,
      ownerIdUrl: d[FirestoreConstants.fldOwnerIdUrl] as String?,
      createdAt: _ts(d[FirestoreConstants.fldCreatedAt]),
      updatedAt: _ts(d[FirestoreConstants.fldUpdatedAt]),
    );
  }

  DateTime _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return DateTime.now();
  }
}
