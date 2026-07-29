import 'package:supabase_flutter/supabase_flutter.dart';

/// A message the admin sent — either a broadcast (to all customers) or a
/// direct message to this shop owner. [read] is computed per-user.
class AdminMessage {
  AdminMessage({
    required this.id,
    required this.audience,
    required this.title,
    required this.body,
    required this.createdAt,
    this.recipientId,
    this.read = false,
  });

  final String id;
  final String audience; // 'broadcast' | 'direct'
  final String? recipientId;
  final String title;
  final String body;
  final DateTime createdAt;
  bool read;

  bool get isBroadcast => audience == 'broadcast';

  factory AdminMessage.fromRow(Map<String, dynamic> r) => AdminMessage(
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

/// Customer-side inbox. RLS on `messages` already limits rows to broadcasts +
/// this user's direct messages, so a plain select is safe.
class MessagesRepository {
  MessagesRepository({SupabaseClient? client})
      : _sb = client ?? Supabase.instance.client;

  final SupabaseClient _sb;

  Future<List<AdminMessage>> fetch() async {
    final rows = await _sb
        .from('messages')
        .select()
        .order('created_at', ascending: false);
    final msgs = (rows as List)
        .map((r) => AdminMessage.fromRow(r as Map<String, dynamic>))
        .toList();

    final uid = _sb.auth.currentUser?.id;
    if (uid != null && msgs.isNotEmpty) {
      final reads = await _sb
          .from('message_reads')
          .select('message_id')
          .eq('profile_id', uid);
      final readIds =
          (reads as List).map((r) => r['message_id'] as String).toSet();
      for (final m in msgs) {
        m.read = readIds.contains(m.id);
      }
    }
    return msgs;
  }

  /// One-shot stream (realtime isn't enabled) — invalidate to refresh.
  Stream<List<AdminMessage>> watch() async* {
    yield await fetch();
  }

  Future<void> markRead(String messageId) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return;
    await _sb.from('message_reads').upsert(
      {'message_id': messageId, 'profile_id': uid},
      onConflict: 'message_id,profile_id',
    );
  }
}
