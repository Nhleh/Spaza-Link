import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../models/advertisement.dart';

/// Reads advertisements for the customer app. RLS only returns ads that are
/// active AND inside their optional schedule window, so no client-side
/// filtering is needed and inactive/expired ads never arrive.
class AdsRepository {
  AdsRepository({supa.SupabaseClient? client})
      : _sb = client ?? supa.Supabase.instance.client;

  final supa.SupabaseClient _sb;

  Future<List<AdvertisementModel>> fetchActive() async {
    final rows = await _sb
        .from('advertisements')
        .select()
        .order('sort_order', ascending: true)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => AdvertisementModel.fromRow(r as Map<String, dynamic>))
        .where((a) => a.imageUrl.isNotEmpty)
        .toList();
  }
}
