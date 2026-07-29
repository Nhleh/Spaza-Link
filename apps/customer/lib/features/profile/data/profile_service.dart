import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Direct Supabase mutations for the signed-in customer's own profile & shop.
///
/// Deliberately kept out of the shared [AuthRepository] interface (which four
/// implementations satisfy) — these are customer-only self-service edits.
class ProfileService {
  ProfileService({SupabaseClient? client})
      : _sb = client ?? Supabase.instance.client;

  final SupabaseClient _sb;

  String? get _uid => _sb.auth.currentUser?.id;

  // ── Personal profile ───────────────────────────────────────────────────────
  Future<void> updateProfile({String? displayName, String? phoneNumber}) async {
    final uid = _uid;
    if (uid == null) return;
    final data = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (displayName != null) data['display_name'] = displayName.trim();
    if (phoneNumber != null) data['phone_number'] = phoneNumber.trim();
    await _sb.from('profiles').update(data).eq('id', uid);
  }

  // ── Preferences (notifications, payment method) ─────────────────────────────
  Future<Map<String, dynamic>> getPreferences() async {
    final uid = _uid;
    if (uid == null) return {};
    final row = await _sb
        .from('profiles')
        .select('preferences')
        .eq('id', uid)
        .maybeSingle();
    final p = row?['preferences'];
    return p is Map ? p.cast<String, dynamic>() : <String, dynamic>{};
  }

  Future<void> setPreferences(Map<String, dynamic> prefs) async {
    final uid = _uid;
    if (uid == null) return;
    await _sb.from('profiles').update({
      'preferences': prefs,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', uid);
  }

  // ── Shop details ────────────────────────────────────────────────────────────
  Future<void> updateShop(
    String shopId, {
    String? shopName,
    String? physicalAddress,
    String? city,
    String? province,
    String? deliveryAddress,
    String? shopPhotoUrl,
  }) async {
    final data = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (shopName != null) data['shop_name'] = shopName.trim();
    if (physicalAddress != null) data['physical_address'] = physicalAddress.trim();
    if (city != null) data['city'] = city.trim();
    if (province != null) data['province'] = province.trim();
    if (deliveryAddress != null) data['delivery_address'] = deliveryAddress.trim();
    if (shopPhotoUrl != null) data['shop_photo_url'] = shopPhotoUrl;
    await _sb.from('shops').update(data).eq('id', shopId);
  }

  Future<String> getShopDeliveryAddress(String shopId) async {
    final row = await _sb
        .from('shops')
        .select('delivery_address')
        .eq('id', shopId)
        .maybeSingle();
    return (row?['delivery_address'] as String?) ?? '';
  }

  Future<String> uploadShopPhoto(Uint8List bytes, String contentType) async {
    final path = 'shop_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storage = _sb.storage.from('shop_photos');
    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType),
    );
    return storage.getPublicUrl(path);
  }

  // ── Password ────────────────────────────────────────────────────────────────
  Future<void> updatePassword(String newPassword) async {
    await _sb.auth.updateUser(UserAttributes(password: newPassword));
  }
}

final profileServiceProvider = Provider<ProfileService>((ref) => ProfileService());
