import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/messages_repository.dart';

final messagesRepositoryProvider =
    Provider<MessagesRepository>((ref) => MessagesRepository());

final messagesProvider = StreamProvider<List<AdminMessage>>((ref) {
  return ref.watch(messagesRepositoryProvider).watch();
});

/// Unread count for the bottom-nav badge.
final unreadMessagesProvider = Provider<int>((ref) {
  final msgs = ref.watch(messagesProvider).valueOrNull ?? const [];
  return msgs.where((m) => !m.read).length;
});
