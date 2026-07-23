import '../models/delivery_model.dart';
import '../models/gps_location.dart';

abstract interface class DeliveryRepository {
  /// Live stream of deliveries assigned to [driverId].
  Stream<List<DeliveryModel>> watchAssignedDeliveries(String driverId);

  Future<DeliveryModel?> getDelivery(String deliveryId);

  Future<void> updateDeliveryStatus({
    required String deliveryId,
    required String status,
    String? proofPhotoUrl,
    String? signatureUrl,
  });

  Future<void> updateDriverLocation({
    required String driverId,
    required GpsLocation location,
  });

  /// Admin: assign a driver to an order, creating a delivery document.
  Future<DeliveryModel> assignDelivery({
    required String orderId,
    required String shopId,
    required String driverId,
    required String deliveryAddress,
  });
}
