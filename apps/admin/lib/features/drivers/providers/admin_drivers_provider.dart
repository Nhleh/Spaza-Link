import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_drivers_repository.dart';

final adminDriversRepositoryProvider =
    Provider<AdminDriversRepository>((ref) => AdminDriversRepository());

/// All active drivers (for the list + the assign picker).
final adminDriversProvider = FutureProvider<List<DriverInfo>>((ref) {
  return ref.watch(adminDriversRepositoryProvider).listDrivers();
});

/// Every order handled by a driver (for the driver detail view).
final driverOrdersProvider =
    FutureProvider.family<List<DriverDelivery>, String>((ref, driverId) {
  return ref.watch(adminDriversRepositoryProvider).driverOrders(driverId);
});

/// A driver's live position (null unless they're actively delivering).
final driverLocationProvider =
    FutureProvider.family<DriverLocation?, String>((ref, driverId) {
  return ref.watch(adminDriversRepositoryProvider).driverLocation(driverId);
});

/// Signed URL for an order's proof-of-delivery slip (null until delivered).
final orderPodUrlProvider =
    FutureProvider.family<String?, String>((ref, orderId) async {
  final repo = ref.watch(adminDriversRepositoryProvider);
  final extras = await repo.deliveryExtras(orderId);
  final path = (extras['pod_path'] as String?) ?? '';
  if (path.isEmpty) return null;
  return repo.signedProofUrl(path);
});
