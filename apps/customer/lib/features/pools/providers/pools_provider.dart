import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/pools_repository.dart';

final poolsRepositoryProvider =
    Provider<PoolsRepository>((ref) => PoolsRepository());

/// Open buying pools (one-shot; invalidate to refresh).
final openPoolsProvider = StreamProvider<List<BuyingPool>>((ref) {
  return ref.watch(poolsRepositoryProvider).watchOpenPools();
});

final poolProvider = FutureProvider.family<BuyingPool?, String>((ref, id) {
  return ref.watch(poolsRepositoryProvider).getPool(id);
});

/// The current user's pledged quantity in a pool (null if not a member).
final myPoolQtyProvider = FutureProvider.family<int?, String>((ref, poolId) {
  return ref.watch(poolsRepositoryProvider).myQuantity(poolId);
});
