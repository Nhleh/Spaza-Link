import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../models/advertisement.dart';

/// Admin CRUD for advertisements + image upload to the public `ad_images`
/// bucket. RLS restricts every write here to admins.
class AdminAdsRepository {
  AdminAdsRepository({supa.SupabaseClient? client})
      : _sb = client ?? supa.Supabase.instance.client;

  final supa.SupabaseClient _sb;

  static const _table = 'advertisements';
  static const _bucket = 'ad_images';

  /// All ads (admin sees active + inactive), newest sort first.
  Future<List<Advertisement>> getAll() async {
    final rows = await _sb
        .from(_table)
        .select()
        .order('sort_order', ascending: true)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => Advertisement.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> create(Advertisement ad) async {
    await _sb.from(_table).insert(ad.toRow());
  }

  Future<void> update(Advertisement ad) async {
    await _sb.from(_table).update(ad.toRow()).eq('id', ad.id);
  }

  Future<void> setActive(String id, bool active) async {
    await _sb.from(_table).update({'active': active}).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _sb.from(_table).delete().eq('id', id);
  }

  /// Uploads [bytes] and returns the public URL.
  Future<String> uploadImage(Uint8List bytes, {required String ext, String? contentType}) async {
    final path = 'ad_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final storage = _sb.storage.from(_bucket);
    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: supa.FileOptions(
        contentType: contentType ?? 'image/jpeg',
        upsert: true,
      ),
    );
    return storage.getPublicUrl(path);
  }
}
