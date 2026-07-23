import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:spazalink_core/core.dart';

/// Watches connectivity and flushes pending offline orders to Firestore.
class CustomerSyncService implements SyncService {
  CustomerSyncService({
    required OrderRepository orderRepository,
  }) : _repo = orderRepository;

  final OrderRepository _repo;

  final _stateController = StreamController<SyncState>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isSyncing = false;

  @override
  Stream<SyncState> get stateStream => _stateController.stream;

  @override
  bool get isSyncing => _isSyncing;

  void start() {
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((results) async {
      final hasNetwork = results
          .any((r) => r != ConnectivityResult.none);
      if (hasNetwork) await syncNow();
    });
  }

  @override
  Future<void> syncNow() async {
    if (_isSyncing) return;
    final pending = await _repo.getPendingOrders();
    if (pending.isEmpty) return;

    _isSyncing = true;
    _stateController.add(SyncState.syncing);

    int failed = 0;
    for (final order in pending) {
      try {
        await _repo.placeOrder(
          order.copyWith(syncStatus: SyncStatus.syncing),
        );
        await _repo.removePendingOrder(order.localUuid);
      } catch (_) {
        failed++;
      }
    }

    _isSyncing = false;
    _stateController.add(failed > 0 ? SyncState.failed : SyncState.idle);
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _stateController.close();
  }
}
