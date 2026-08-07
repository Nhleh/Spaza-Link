import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../models/savings.dart';

/// Reads the per-order savings columns (written at checkout) for the signed-in
/// customer and returns them as [SavingEntry]s. Cancelled orders are excluded.
class SavingsRepository {
  SavingsRepository({supa.SupabaseClient? client})
      : _sb = client ?? supa.Supabase.instance.client;

  final supa.SupabaseClient _sb;

  Future<List<SavingEntry>> fetchForCustomer(String customerId) async {
    if (customerId.isEmpty) return const [];
    final rows = await _sb
        .from('orders')
        .select(
            'created_at, status, discount_saved_cents, pool_saved_cents, delivery_saved_cents')
        .eq('customer_id', customerId)
        .neq('status', 'cancelled')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => SavingEntry.fromRow(r as Map<String, dynamic>))
        .toList();
  }
}
