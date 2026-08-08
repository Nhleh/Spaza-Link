import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../models/delivery.dart';

/// Supabase data for the driver's own deliveries. RLS limits every read/write
/// to orders where `driver_id = auth.uid()`.
class DriverDeliveryRepository {
  DriverDeliveryRepository({supa.SupabaseClient? client})
      : _sb = client ?? supa.Supabase.instance.client;

  final supa.SupabaseClient _sb;

  String? get _uid => _sb.auth.currentUser?.id;

  static const _select =
      '*, order_items(*), shops(shop_name, physical_address, city)';

  /// Active jobs: assigned (to pick up) or out for delivery.
  Future<List<Delivery>> myActiveDeliveries() async {
    final uid = _uid;
    if (uid == null) return const [];
    final rows = await _sb
        .from('orders')
        .select(_select)
        .eq('driver_id', uid)
        .inFilter('status', ['assigned', 'out_for_delivery'])
        .order('created_at', ascending: true);
    return (rows as List)
        .map((r) => Delivery.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  Future<Delivery?> getDelivery(String orderId) async {
    final row = await _sb
        .from('orders')
        .select(_select)
        .eq('id', orderId)
        .maybeSingle();
    return row == null ? null : Delivery.fromRow(row);
  }

  /// Driver picked the order up from the shop → out for delivery. The DB
  /// notification then tells the customer "on the way".
  Future<void> confirmPickup(String orderId) async {
    await _sb.from('orders').update({
      'status': 'out_for_delivery',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }

  /// Delivered: upload the signature + signed slip, mark delivered, and (for
  /// cash on delivery) flip payment to paid when the driver confirms cash.
  Future<void> completeDelivery({
    required String orderId,
    required Uint8List signaturePng,
    required Uint8List slipPng,
    required bool cashCollected,
    required String paymentMethod,
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final storage = _sb.storage.from('delivery_proofs');
    final sigPath = 'sig_${orderId}_$ts.png';
    final podPath = 'pod_${orderId}_$ts.png';

    await storage.uploadBinary(sigPath, signaturePng,
        fileOptions: const supa.FileOptions(contentType: 'image/png', upsert: true));
    await storage.uploadBinary(podPath, slipPng,
        fileOptions: const supa.FileOptions(contentType: 'image/png', upsert: true));

    final payStatus =
        (paymentMethod == 'cod' && cashCollected) ? 'paid' : 'pending';

    await _sb.from('orders').update({
      'status': 'delivered',
      'payment_status': payStatus,
      'signature_path': sigPath,
      'pod_path': podPath,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }

  /// Upsert the driver's live position (called by the location service).
  Future<void> reportLocation(double lat, double lng) async {
    final uid = _uid;
    if (uid == null) return;
    await _sb.from('driver_locations').upsert({
      'driver_id': uid,
      'lat': lat,
      'lng': lng,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
