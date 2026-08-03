import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_pools_repository.dart';

final adminPoolsRepositoryProvider =
    Provider<AdminPoolsRepository>((ref) => AdminPoolsRepository());

final adminPoolsProvider = StreamProvider<List<AdminPool>>((ref) {
  return ref.watch(adminPoolsRepositoryProvider).watchPools();
});

final adminPoolMembersProvider =
    FutureProvider.family<List<AdminPoolMember>, String>((ref, poolId) {
  return ref.watch(adminPoolsRepositoryProvider).fetchMembers(poolId);
});
