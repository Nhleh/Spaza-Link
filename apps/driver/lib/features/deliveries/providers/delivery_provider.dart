import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';

import '../data/firebase_delivery_repository.dart';
import '../../auth/providers/driver_auth_provider.dart';

final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  return FirebaseDeliveryRepository();
});

/// Live stream of active deliveries for the signed-in driver.
final assignedDeliveriesProvider =
    StreamProvider<List<DeliveryModel>>((ref) {
  final uid = ref.watch(driverAuthUidProvider).valueOrNull;
  if (uid == null) return const Stream.empty();
  return ref
      .watch(deliveryRepositoryProvider)
      .watchAssignedDeliveries(uid);
});

final deliveryDetailProvider =
    FutureProvider.family<DeliveryModel?, String>((ref, deliveryId) {
  return ref.watch(deliveryRepositoryProvider).getDelivery(deliveryId);
});

// ── Delivery action notifier ──────────────────────────────────────────────────

sealed class DeliveryActionState {}

class DeliveryActionIdle extends DeliveryActionState {}

class DeliveryActionLoading extends DeliveryActionState {}

class DeliveryActionSuccess extends DeliveryActionState {}

class DeliveryActionError extends DeliveryActionState {
  DeliveryActionError(this.message);
  final String message;
}

class DeliveryActionNotifier extends Notifier<DeliveryActionState> {
  @override
  DeliveryActionState build() => DeliveryActionIdle();

  DeliveryRepository get _repo => ref.read(deliveryRepositoryProvider);

  Future<void> markEnRoute(String deliveryId) =>
      _updateStatus(deliveryId, DeliveryStatus.enRoute);

  Future<void> markArrived(String deliveryId) =>
      _updateStatus(deliveryId, DeliveryStatus.arrived);

  Future<void> markDelivered({
    required String deliveryId,
    String? proofPhotoUrl,
    String? signatureUrl,
  }) async {
    state = DeliveryActionLoading();
    try {
      await _repo.updateDeliveryStatus(
        deliveryId: deliveryId,
        status: DeliveryStatus.delivered,
        proofPhotoUrl: proofPhotoUrl,
        signatureUrl: signatureUrl,
      );
      state = DeliveryActionSuccess();
    } catch (e) {
      state = DeliveryActionError(e.toString());
    }
  }

  Future<void> markFailed(String deliveryId) =>
      _updateStatus(deliveryId, DeliveryStatus.failed);

  Future<void> updateLocation({
    required String driverId,
    required GpsLocation location,
  }) async {
    try {
      await _repo.updateDriverLocation(
          driverId: driverId, location: location);
    } catch (_) {
      // Location updates are best-effort; silently ignore failures.
    }
  }

  Future<void> _updateStatus(String deliveryId, String status) async {
    state = DeliveryActionLoading();
    try {
      await _repo.updateDeliveryStatus(
        deliveryId: deliveryId,
        status: status,
      );
      state = DeliveryActionSuccess();
    } catch (e) {
      state = DeliveryActionError(e.toString());
    }
  }

  void reset() => state = DeliveryActionIdle();
}

final deliveryActionProvider =
    NotifierProvider<DeliveryActionNotifier, DeliveryActionState>(
        DeliveryActionNotifier.new);
