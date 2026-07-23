import 'package:freezed_annotation/freezed_annotation.dart';

part 'cart_item_model.freezed.dart';
part 'cart_item_model.g.dart';

@freezed
class CartItemModel with _$CartItemModel {
  const factory CartItemModel({
    required String productId,
    required String shopId,
    required String productName,
    String? imageUrl,
    required int priceCents,
    int? salePriceCents,
    @Default('') String packSize,
    required int quantity,
    @_DtConverter() required DateTime addedAt,
  }) = _CartItemModel;

  factory CartItemModel.fromJson(Map<String, dynamic> json) =>
      _$CartItemModelFromJson(json);
}

extension CartItemModelX on CartItemModel {
  int get effectivePriceCents => salePriceCents ?? priceCents;
  int get lineTotalCents => effectivePriceCents * quantity;
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
