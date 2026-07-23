import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';

import '../../orders/providers/order_provider.dart';
import '../services/customer_sync_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final service = CustomerSyncService(
    orderRepository: ref.read(orderRepositoryProvider),
  );
  service.start();
  ref.onDispose(service.dispose);
  return service;
});

final syncStateProvider = StreamProvider<SyncState>((ref) {
  return ref.watch(syncServiceProvider).stateStream;
});
