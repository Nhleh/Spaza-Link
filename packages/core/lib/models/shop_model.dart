import 'package:freezed_annotation/freezed_annotation.dart';

import 'gps_location.dart';

part 'shop_model.freezed.dart';
part 'shop_model.g.dart';

@freezed
class ShopModel with _$ShopModel {
  const factory ShopModel({
    @Default('') String id,
    required String ownerId,
    required String shopName,
    required String ownerName,
    required String physicalAddress,
    @Default('') String city,
    @Default('') String province,
    GpsLocation? gpsLocation,
    @Default('pending') String status,
    String? rejectionReason,
    String? approvedBy,
    @_NullableDateTimeConverter() DateTime? approvedAt,
    @_DateTimeConverter() required DateTime createdAt,
    @_DateTimeConverter() required DateTime updatedAt,
    String? shopPhotoUrl,
    String? businessRegUrl,
    String? ownerIdUrl,
  }) = _ShopModel;

  factory ShopModel.fromJson(Map<String, dynamic> json) =>
      _$ShopModelFromJson(json);
}

class _DateTimeConverter implements JsonConverter<DateTime, dynamic> {
  const _DateTimeConverter();

  @override
  DateTime fromJson(dynamic json) {
    if (json is int) return DateTime.fromMillisecondsSinceEpoch(json);
    if (json is String) return DateTime.parse(json);
    return DateTime.now();
  }

  @override
  dynamic toJson(DateTime date) => date.millisecondsSinceEpoch;
}

class _NullableDateTimeConverter
    implements JsonConverter<DateTime?, dynamic> {
  const _NullableDateTimeConverter();

  @override
  DateTime? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is int) return DateTime.fromMillisecondsSinceEpoch(json);
    if (json is String) return DateTime.parse(json);
    return null;
  }

  @override
  dynamic toJson(DateTime? date) =>
      date == null ? null : date.millisecondsSinceEpoch;
}
