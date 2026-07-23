import 'package:freezed_annotation/freezed_annotation.dart';

import 'gps_location.dart';

part 'delivery_model.freezed.dart';
part 'delivery_model.g.dart';

abstract final class DeliveryStatus {
  static const String assigned = 'assigned';
  static const String enRoute = 'en_route';
  static const String arrived = 'arrived';
  static const String delivered = 'delivered';
  static const String failed = 'failed';
}

@freezed
class DeliveryModel with _$DeliveryModel {
  const factory DeliveryModel({
    @Default('') String id,
    required String orderId,
    required String driverId,
    required String shopId,
    required String deliveryAddress,
    @Default(DeliveryStatus.assigned) String status,
    @_NullableDtConverter() DateTime? estimatedArrival,
    String? proofPhotoUrl,
    String? signatureUrl,
    @_NullableDtConverter() DateTime? deliveredAt,
    @_DtConverter() required DateTime assignedAt,
    String? notes,
    GpsLocation? currentLocation,
  }) = _DeliveryModel;

  factory DeliveryModel.fromJson(Map<String, dynamic> json) =>
      _$DeliveryModelFromJson(json);
}

class _DtConverter implements JsonConverter<DateTime, dynamic> {
  const _DtConverter();
  @override
  DateTime fromJson(dynamic v) {
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) return DateTime.parse(v);
    return DateTime.now();
  }
  @override
  dynamic toJson(DateTime d) => d.millisecondsSinceEpoch;
}

class _NullableDtConverter implements JsonConverter<DateTime?, dynamic> {
  const _NullableDtConverter();
  @override
  DateTime? fromJson(dynamic v) {
    if (v == null) return null;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) return DateTime.parse(v);
    return null;
  }
  @override
  dynamic toJson(DateTime? d) => d?.millisecondsSinceEpoch;
}
