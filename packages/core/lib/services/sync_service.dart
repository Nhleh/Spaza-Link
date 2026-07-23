/// Contract for the offline-sync service.
///
/// The concrete implementation lives in each app's features/sync/ directory.
/// The customer app is the only one that actually queues orders offline;
/// other apps can use a no-op implementation.
abstract class SyncService {
  Stream<SyncState> get stateStream;
  bool get isSyncing;
  Future<void> syncNow();
  void dispose();
}

enum SyncState { idle, syncing, failed }
