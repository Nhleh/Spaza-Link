import 'package:supabase_flutter/supabase_flutter.dart' as supa;

/// A driver account (from the `list_drivers()` RPC).
class DriverInfo {
  const DriverInfo({required this.id, required this.name, required this.phone});
  final String id;
  final String name;
  final String phone;

  factory DriverInfo.fromRow(Map<String, dynamic> r) => DriverInfo(
        id: r['id'] as String,
        name: (r['display_name'] as String?)?.trim().isNotEmpty == true
            ? r['display_name'] as String
            : 'Driver',
        phone: (r['phone_number'] as String?) ?? '',
      );
}

/// One order handled by a driver.
class DriverDelivery {
  const DriverDelivery({
    required this.orderId,
    required this.status,
    required this.totalCents,
    required this.placedAt,
    this.deliveredAt,
    this.deliveryAddress = '',
  });

  final String orderId;
  final String status;
  final int totalCents;
  final DateTime placedAt;
  final DateTime? deliveredAt;
  final String deliveryAddress;

  String get ref => orderId.split('-').first.toUpperCase();
  bool get isActive => status == 'assigned' || status == 'out_for_delivery';
  bool get isDelivered => status == 'delivered';

  factory DriverDelivery.fromRow(Map<String, dynamic> r) {
    DateTime? dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());
    return DriverDelivery(
      orderId: r['id'] as String? ?? '',
      status: r['status'] as String? ?? 'pending',
      totalCents: (r['total_cents'] as num?)?.toInt() ?? 0,
      placedAt: dt(r['created_at']) ?? DateTime.now(),
      deliveredAt: dt(r['delivered_at']),
      deliveryAddress: r['delivery_address'] as String? ?? '',
    );
  }
}

/// A driver's last reported position (only readable while actively delivering).
class DriverLocation {
  const DriverLocation({required this.lat, required this.lng, required this.updatedAt});
  final double lat;
  final double lng;
  final DateTime updatedAt;
}

class AdminDriversRepository {
  AdminDriversRepository({supa.SupabaseClient? client})
      : _sb = client ?? supa.Supabase.instance.client;

  final supa.SupabaseClient _sb;

  /// All active driver accounts.
  Future<List<DriverInfo>> listDrivers() async {
    final rows = await _sb.rpc('list_drivers');
    return (rows as List)
        .map((r) => DriverInfo.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  /// Assign an order to a driver with the pickup location. Sets status=assigned.
  Future<void> assignOrder({
    required String orderId,
    required String driverId,
    required String pickupAddress,
  }) async {
    await _sb.from('orders').update({
      'driver_id': driverId,
      'pickup_address': pickupAddress.trim(),
      'status': 'assigned',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }

  /// Create a driver account. Done client-side without a service-role key:
  /// sign the new user up, immediately restore the admin session, then (as
  /// admin) set the new user's role to 'driver'.
  ///
  /// Note: if "Confirm email" is enabled in Supabase Auth, the driver must
  /// confirm their email before their first login.
  Future<void> createDriver({
    required String email,
    required String password,
    required String name,
    String phone = '',
  }) async {
    final adminSession = _sb.auth.currentSession;
    final adminRefresh = adminSession?.refreshToken;
    if (adminRefresh == null) {
      throw Exception('Your admin session expired — please sign in again.');
    }

    String? driverId;
    try {
      final res = await _sb.auth.signUp(email: email.trim(), password: password);
      driverId = res.user?.id;
    } finally {
      // Always return to the admin session, even if signUp threw.
      await _sb.auth.setSession(adminRefresh);
    }

    if (driverId == null) {
      throw Exception('Could not create the driver account.');
    }

    await _sb.from('profiles').update({
      'role': 'driver',
      'display_name': name.trim(),
      'phone_number': phone.trim(),
      'email': email.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', driverId);
  }

  /// Every order ever handed to this driver (newest first) — for the driver
  /// detail view (today's count, what they delivered, current job).
  Future<List<DriverDelivery>> driverOrders(String driverId) async {
    final rows = await _sb
        .from('orders')
        .select('id, status, total_cents, created_at, delivered_at, delivery_address')
        .eq('driver_id', driverId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => DriverDelivery.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  /// The driver's latest position — returns null unless they're actively
  /// delivering (enforced by RLS).
  Future<DriverLocation?> driverLocation(String driverId) async {
    final row = await _sb
        .from('driver_locations')
        .select()
        .eq('driver_id', driverId)
        .maybeSingle();
    if (row == null) return null;
    return DriverLocation(
      lat: (row['lat'] as num).toDouble(),
      lng: (row['lng'] as num).toDouble(),
      updatedAt:
          DateTime.tryParse(row['updated_at'].toString()) ?? DateTime.now(),
    );
  }

  /// Extra delivery fields for the admin order-detail view (not on OrderModel).
  Future<Map<String, dynamic>> deliveryExtras(String orderId) async {
    final row = await _sb
        .from('orders')
        .select(
            'delivery_address, pickup_address, driver_id, payment_status, delivered_at, pod_path, signature_path')
        .eq('id', orderId)
        .maybeSingle();
    return row ?? {};
  }

  /// A short-lived signed URL for a private proof-of-delivery object.
  Future<String?> signedProofUrl(String path) async {
    if (path.isEmpty) return null;
    try {
      return await _sb.storage
          .from('delivery_proofs')
          .createSignedUrl(path, 60 * 60);
    } catch (_) {
      return null;
    }
  }
}
