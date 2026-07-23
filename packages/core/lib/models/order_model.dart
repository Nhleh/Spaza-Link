import 'package:freezed_annotation/freezed_annotation.dart';

import 'order_item_model.dart';

part 'order_model.freezed.dart';
part 'order_model.g.dart';

/// Order statuses (Firestore-synced).
abstract final class OrderStatus {
  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String preparing = 'preparing';
  static const String outForDelivery = 'out_for_delivery';
  static const String delivered = 'delivered';
  static const String cancelled = 'cancelled';
}

/// Sync state for offline-queued orders (local only, not in Firestore).
abstract final class SyncStatus {
  static const String local = 'local';
  static const String syncing = 'syncing';
  static const String synced = 'synced';
  static const String failed = 'failed';
}

abstract final class PaymentMethod {
  static const String payfast = 'payfast';
  static const String ozow = 'ozow';
  static const String yoco = 'yoco';
  static const String cod = 'cod';
}

abstract final class PaymentStatus {
  static const String pending = 'pending';
  static const String paid = 'paid';
  static const String failed = 'failed';
  static const String refunded = 'refunded';
}

@freezed
class OrderModel with _$OrderModel {
  const factory OrderModel({
    @Default('') String id,
    required String localUuid,
    @Default('') String orderNumber,
    required String shopId,
    required String customerId,
    @Default(OrderStatus.pending) String status,
    @Default(SyncStatus.local) String syncStatus,
    @Default([]) List<OrderItemModel> items,
    required int subtotalCents,
    required int deliveryFeeCents,
    @Default(0) int discountAmountCents,
    required int totalCents,
    required String deliveryAddress,
    String? notes,
    @Default(PaymentMethod.cod) String paymentMethod,
    @Default(PaymentStatus.pending) String paymentStatus,
    @_NullableDtConverter() DateTime? scheduledDeliveryDate,
    String? driverId,
    String? deliveryId,
    @_DtConverter() required DateTime placedAt,
    @_DtConverter() required DateTime createdAt,
    @_DtConverter() required DateTime updatedAt,
  }) = _OrderModel;

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);
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
