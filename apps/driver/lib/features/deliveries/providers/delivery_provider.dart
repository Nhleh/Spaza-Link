import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/driver_auth_provider.dart';
import '../data/driver_delivery_repository.dart';
import '../models/delivery.dart';

final driverDeliveryRepositoryProvider =
    Provider<DriverDeliveryRepository>((ref) => DriverDeliveryRepository());

/// The signed-in driver's active jobs (assigned + out for delivery).
final myDeliveriesProvider = FutureProvider<List<Delivery>>((ref) {
  final uid = ref.watch(driverAuthUidProvider).valueOrNull;
  if (uid == null) return Future.value(const <Delivery>[]);
  return ref.watch(driverDeliveryRepositoryProvider).myActiveDeliveries();
});

final deliveryDetailProvider =
    FutureProvider.family<Delivery?, String>((ref, orderId) {
  return ref.watch(driverDeliveryRepositoryProvider).getDelivery(orderId);
});

/// Completed deliveries (History + stats).
final myHistoryProvider = FutureProvider<List<Delivery>>((ref) {
  final uid = ref.watch(driverAuthUidProvider).valueOrNull;
  if (uid == null) return Future.value(const <Delivery>[]);
  return ref.watch(driverDeliveryRepositoryProvider).myHistory();
});
