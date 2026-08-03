import 'package:supabase_flutter/supabase_flutter.dart';

int poolDiscountPct(int qty) =>
    qty >= 150 ? 15 : (qty >= 100 ? 10 : (qty >= 50 ? 5 : 0));

class AdminPoolMember {
  AdminPoolMember({required this.name, required this.quantity});
  final String name;
  final int quantity;
}

class AdminPool {
  AdminPool({
    required this.id,
    required this.productName,
    required this.creatorId,
    required this.status,
    required this.targetQty,
    required this.unitPriceCents,
    required this.createdAt,
    required this.closesAt,
    this.totalQty = 0,
    this.memberCount = 0,
    this.creatorName = '',
  });

  final String id;
  final String productName;
  final String creatorId;
  final String status;
  final int targetQty;
  final int unitPriceCents;
  final DateTime createdAt;
  final DateTime closesAt;

  int totalQty;
  int memberCount;
  String creatorName;

  int get discountPct => poolDiscountPct(totalQty);
  bool get isExpired => DateTime.now().isAfter(closesAt);
  String get effectiveStatus =>
      status == 'open' && isExpired ? 'expired' : status;

  Duration get timeLeft => closesAt.difference(DateTime.now());

  factory AdminPool.fromRow(Map<String, dynamic> r) => AdminPool(
        id: r['id'] as String,
        productName: (r['product_name'] as String?) ?? '',
        creatorId: (r['creator_id'] as String?) ?? '',
        status: (r['status'] as String?) ?? 'open',
        targetQty: (r['target_qty'] as num?)?.toInt() ?? 0,
        unitPriceCents: (r['unit_price_cents'] as num?)?.toInt() ?? 0,
        createdAt:
            DateTime.tryParse(r['created_at']?.toString() ?? '')?.toLocal() ??
                DateTime.now(),
        closesAt:
            DateTime.tryParse(r['closes_at']?.toString() ?? '')?.toLocal() ??
                DateTime.now(),
      );
}

class AdminPoolsRepository {
  AdminPoolsRepository({SupabaseClient? client})
      : _sb = client ?? Supabase.instance.client;
  final SupabaseClient _sb;

  /// All pools (newest first) with live totals + creator names merged in.
  Future<List<AdminPool>> fetchPools() async {
    final rows = await _sb
        .from('buying_pools')
        .select()
        .order('created_at', ascending: false);
    final pools = (rows as List)
        .map((e) => AdminPool.fromRow(e as Map<String, dynamic>))
        .toList();
    if (pools.isEmpty) return pools;

    // Totals
    final ids = pools.map((p) => p.id).toList();
    final totals = await _sb
        .from('pool_totals')
        .select('pool_id,total_qty,member_count')
        .inFilter('pool_id', ids);
    final tById = {for (final t in totals as List) t['pool_id'] as String: t};

    // Creator names
    final creatorIds = pools.map((p) => p.creatorId).toSet().toList();
    final profs = await _sb
        .from('profiles')
        .select('id,display_name')
        .inFilter('id', creatorIds);
    final nameById = {
      for (final p in profs as List)
        p['id'] as String: (p['display_name'] as String?) ?? '',
    };

    for (final p in pools) {
      final t = tById[p.id];
      p.totalQty = (t?['total_qty'] as num?)?.toInt() ?? 0;
      p.memberCount = (t?['member_count'] as num?)?.toInt() ?? 0;
      p.creatorName = nameById[p.creatorId] ?? '—';
    }
    return pools;
  }

  Stream<List<AdminPool>> watchPools() async* {
    yield await fetchPools();
  }

  /// Members of a pool with their pledged quantities + names.
  Future<List<AdminPoolMember>> fetchMembers(String poolId) async {
    final rows = await _sb
        .from('pool_members')
        .select('member_id,quantity')
        .eq('pool_id', poolId)
        .order('quantity', ascending: false);
    final list = rows as List;
    if (list.isEmpty) return [];
    final ids = list.map((e) => e['member_id'] as String).toSet().toList();
    final profs = await _sb
        .from('profiles')
        .select('id,display_name')
        .inFilter('id', ids);
    final nameById = {
      for (final p in profs as List)
        p['id'] as String: (p['display_name'] as String?) ?? '',
    };
    return list
        .map((e) => AdminPoolMember(
              name: nameById[e['member_id']] ?? 'Shop',
              quantity: (e['quantity'] as num?)?.toInt() ?? 0,
            ))
        .toList();
  }
}
