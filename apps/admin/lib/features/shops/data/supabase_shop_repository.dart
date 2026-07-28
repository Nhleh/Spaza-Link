import 'package:spazalink_core/core.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

/// Supabase-backed shop admin: list by status, approve / reject / suspend.
class SupabaseShopRepository {
  SupabaseShopRepository({supa.SupabaseClient? client})
      : _sb = client ?? supa.Supabase.instance.client;

  final supa.SupabaseClient _sb;

  /// One-shot stream (re-run by invalidating the provider after a change).
  Stream<List<ShopModel>> watchShops({String? status}) async* {
    var q = _sb.from('shops').select();
    if (status != null) q = q.eq('status', status);
    final rows = await q.order('created_at', ascending: false);
    yield (rows as List)
        .map((e) => _fromRow(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> approveShop(String shopId, String adminUid) async {
    await _sb.from('shops').update({
      'status': AppConstants.shopStatusApproved,
      'approved_by': adminUid,
      'approved_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', shopId);
  }

  Future<void> rejectShop(String shopId, String reason) async {
    await _sb.from('shops').update({
      'status': AppConstants.shopStatusRejected,
      'rejection_reason': reason,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', shopId);
  }

  Future<void> suspendShop(String shopId, String reason) async {
    await _sb.from('shops').update({
      'status': AppConstants.shopStatusSuspended,
      'rejection_reason': reason,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', shopId);
  }

  ShopModel _fromRow(Map<String, dynamic> d) => ShopModel(
        id: d['id'] as String,
        ownerId: (d['owner_id'] as String?) ?? '',
        shopName: (d['shop_name'] as String?) ?? '',
        ownerName: (d['owner_name'] as String?) ?? '',
        physicalAddress: (d['physical_address'] as String?) ?? '',
        city: (d['city'] as String?) ?? '',
        province: (d['province'] as String?) ?? '',
        gpsLocation: (d['gps_lat'] != null && d['gps_lng'] != null)
            ? GpsLocation(
                latitude: (d['gps_lat'] as num).toDouble(),
                longitude: (d['gps_lng'] as num).toDouble())
            : null,
        status: (d['status'] as String?) ?? AppConstants.shopStatusPending,
        rejectionReason: d['rejection_reason'] as String?,
        approvedBy: d['approved_by'] as String?,
        approvedAt: d['approved_at'] is String
            ? DateTime.tryParse(d['approved_at'])
            : null,
        shopPhotoUrl: d['shop_photo_url'] as String?,
        businessRegUrl: d['business_reg_url'] as String?,
        ownerIdUrl: d['owner_id_url'] as String?,
        createdAt: _dt(d['created_at']),
        updatedAt: _dt(d['updated_at']),
      );

  DateTime _dt(dynamic v) =>
      v is String ? (DateTime.tryParse(v) ?? DateTime.now()) : DateTime.now();
}
