import 'package:supabase_flutter/supabase_flutter.dart';

class SentMessage {
  SentMessage({
    required this.id,
    required this.audience,
    required this.title,
    required this.body,
    required this.createdAt,
    this.recipientId,
  });

  final String id;
  final String audience;
  final String? recipientId;
  final String title;
  final String body;
  final DateTime createdAt;

  bool get isBroadcast => audience == 'broadcast';

  factory SentMessage.fromRow(Map<String, dynamic> r) => SentMessage(
        id: r['id'] as String,
        audience: (r['audience'] as String?) ?? 'broadcast',
        recipientId: r['recipient_id'] as String?,
        title: (r['title'] as String?) ?? '',
        body: (r['body'] as String?) ?? '',
        createdAt:
            DateTime.tryParse(r['created_at']?.toString() ?? '')?.toLocal() ??
                DateTime.now(),
      );
}

/// A shop owner the admin can message directly.
class OwnerOption {
  OwnerOption(
      {required this.ownerId, required this.shopName, required this.ownerName});
  final String ownerId; // == profile id == messages.recipient_id
  final String shopName;
  final String ownerName;
}

class AdminMessagingRepository {
  AdminMessagingRepository({SupabaseClient? client})
      : _sb = client ?? Supabase.instance.client;

  final SupabaseClient _sb;

  Future<void> sendBroadcast(String title, String body) =>
      _send('broadcast', null, title, body);

  Future<void> sendDirect(String recipientId, String title, String body) =>
      _send('direct', recipientId, title, body);

  Future<void> _send(
      String audience, String? recipientId, String title, String body) async {
    await _sb.from('messages').insert({
      'audience': audience,
      'recipient_id': recipientId,
      'title': title.trim(),
      'body': body.trim(),
      'created_by': _sb.auth.currentUser?.id,
    });
  }

  Future<List<SentMessage>> fetchSent() async {
    final rows = await _sb
        .from('messages')
        .select()
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => SentMessage.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  Stream<List<SentMessage>> watchSent() async* {
    yield await fetchSent();
  }

  Future<List<OwnerOption>> fetchOwners() async {
    final rows = await _sb
        .from('shops')
        .select('owner_id, shop_name, owner_name')
        .order('shop_name');
    return (rows as List)
        .map((r) => OwnerOption(
              ownerId: (r['owner_id'] as String?) ?? '',
              shopName: (r['shop_name'] as String?) ?? '',
              ownerName: (r['owner_name'] as String?) ?? '',
            ))
        .where((o) => o.ownerId.isNotEmpty)
        .toList();
  }
}
