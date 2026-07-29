import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_messaging_repository.dart';

final adminMessagingRepositoryProvider =
    Provider<AdminMessagingRepository>((ref) => AdminMessagingRepository());

final sentMessagesProvider = StreamProvider<List<SentMessage>>((ref) {
  return ref.watch(adminMessagingRepositoryProvider).watchSent();
});

final ownerOptionsProvider = FutureProvider<List<OwnerOption>>((ref) {
  return ref.watch(adminMessagingRepositoryProvider).fetchOwners();
});
