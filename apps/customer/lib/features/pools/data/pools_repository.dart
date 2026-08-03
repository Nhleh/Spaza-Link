import 'package:spazalink_core/core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Discount tier (percent) for a pooled quantity: 50→5, 100→10, 150→15 (max).
int poolDiscountPct(int qty) =>
    qty >= 150 ? 15 : (qty >= 100 ? 10 : (qty >= 50 ? 5 : 0));

/// Minimum quantity to create a pool.
const int kPoolMinCreateQty = 50;

/// A customer-created buying pool for a single product.
class BuyingPool {
  BuyingPool({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.unitPriceCents,
    required this.creatorId,
    required this.targetQty,
    required this.status,
    required this.createdAt,
    required this.closesAt,
    this.totalQty = 0,
    this.memberCount = 0,
  });

  final String id;
  final String productId;
  final String productName;
  final String productImage;
  final int unitPriceCents; // customer-facing price (already marked up)
  final String creatorId;
  final int targetQty;
  final String status;
  final DateTime createdAt;
  final DateTime closesAt;

  int totalQty;
  int memberCount;

  int get discountPct => poolDiscountPct(totalQty);

  bool get isExpired => DateTime.now().isAfter(closesAt);

  /// Joinable = still open and within the 3-day window.
  bool get isOpen => status == 'open' && !isExpired;

  Duration get timeLeft => closesAt.difference(DateTime.now());

  /// Quantity needed to reach the next discount tier (0 if already at max).
  int get nextTierAt => totalQty < 50
      ? 50
      : totalQty < 100
          ? 100
          : totalQty < 150
              ? 150
              : 0;

  int get nextTierPct => totalQty < 50
      ? 5
      : totalQty < 100
          ? 10
          : totalQty < 150
              ? 15
              : 15;

  /// Discounted unit price (cents) at the current tier.
  int get discountedUnitCents =>
      (unitPriceCents * (100 - discountPct) / 100).round();

  factory BuyingPool.fromRow(Map<String, dynamic> r) => BuyingPool(
        id: r['id'] as String,
        productId: (r['product_id'] as String?) ?? '',
        productName: (r['product_name'] as String?) ?? '',
        productImage: (r['product_image'] as String?) ?? '',
        unitPriceCents: (r['unit_price_cents'] as num?)?.toInt() ?? 0,
        creatorId: (r['creator_id'] as String?) ?? '',
        targetQty: (r['target_qty'] as num?)?.toInt() ?? 50,
        status: (r['status'] as String?) ?? 'open',
        createdAt:
            DateTime.tryParse(r['created_at']?.toString() ?? '')?.toLocal() ??
                DateTime.now(),
        closesAt:
            DateTime.tryParse(r['closes_at']?.toString() ?? '')?.toLocal() ??
                DateTime.now().add(const Duration(days: 3)),
      );
}

class PoolMember {
  PoolMember({required this.memberId, required this.quantity});
  final String memberId;
  final int quantity;
}

class PoolsRepository {
  PoolsRepository({SupabaseClient? client})
      : _sb = client ?? Supabase.instance.client;

  final SupabaseClient _sb;

  String? get _uid => _sb.auth.currentUser?.id;

  /// Open pools (newest first) with live totals merged in.
  Future<List<BuyingPool>> fetchOpenPools() async {
    final rows = await _sb
        .from('buying_pools')
        .select()
        .eq('status', 'open')
        .order('created_at', ascending: false);
    final pools = (rows as List)
        .map((e) => BuyingPool.fromRow(e as Map<String, dynamic>))
        .where((p) => p.isOpen) // hide time-expired
        .toList();
    await _mergeTotals(pools);
    return pools;
  }

  Future<BuyingPool?> getPool(String id) async {
    final row =
        await _sb.from('buying_pools').select().eq('id', id).maybeSingle();
    if (row == null) return null;
    final pool = BuyingPool.fromRow(row);
    await _mergeTotals([pool]);
    return pool;
  }

  Future<void> _mergeTotals(List<BuyingPool> pools) async {
    if (pools.isEmpty) return;
    final ids = pools.map((p) => p.id).toList();
    final totals = await _sb
        .from('pool_totals')
        .select('pool_id,total_qty,member_count')
        .inFilter('pool_id', ids);
    final byId = {
      for (final t in totals as List) t['pool_id'] as String: t,
    };
    for (final p in pools) {
      final t = byId[p.id];
      p.totalQty = (t?['total_qty'] as num?)?.toInt() ?? 0;
      p.memberCount = (t?['member_count'] as num?)?.toInt() ?? 0;
    }
  }

  Stream<List<BuyingPool>> watchOpenPools() async* {
    yield await fetchOpenPools();
  }

  /// The current user's pledged quantity in a pool, or null if not a member.
  Future<int?> myQuantity(String poolId) async {
    final uid = _uid;
    if (uid == null) return null;
    final row = await _sb
        .from('pool_members')
        .select('quantity')
        .eq('pool_id', poolId)
        .eq('member_id', uid)
        .maybeSingle();
    return (row?['quantity'] as num?)?.toInt();
  }

  /// Create a pool for [product], pledging [quantity] (>= 50) with [targetQty].
  Future<BuyingPool> createPool({
    required ProductModel product,
    required int quantity,
    required int targetQty,
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not signed in');
    final inserted = await _sb
        .from('buying_pools')
        .insert({
          'product_id': product.id,
          'product_name': product.name,
          'product_image': product.primaryImageUrl ?? '',
          'unit_price_cents': product.priceCents,
          'creator_id': uid,
          'target_qty': targetQty,
        })
        .select()
        .single();
    final pool = BuyingPool.fromRow(inserted);
    // Creator is the first member.
    await _sb.from('pool_members').insert({
      'pool_id': pool.id,
      'member_id': uid,
      'quantity': quantity,
    });
    await _mergeTotals([pool]);
    return pool;
  }

  /// Join (or update pledge in) a pool with [quantity].
  Future<void> joinPool({required String poolId, required int quantity}) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not signed in');
    await _sb.from('pool_members').upsert({
      'pool_id': poolId,
      'member_id': uid,
      'quantity': quantity,
    }, onConflict: 'pool_id,member_id');
  }

  Future<void> leavePool(String poolId) async {
    final uid = _uid;
    if (uid == null) return;
    await _sb
        .from('pool_members')
        .delete()
        .eq('pool_id', poolId)
        .eq('member_id', uid);
  }
}
