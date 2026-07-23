import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_model.freezed.dart';
part 'product_model.g.dart';

@freezed
class ProductModel with _$ProductModel {
  const factory ProductModel({
    @Default('') String id,
    required String categoryId,
    required String name,
    @Default('') String description,
    @Default('') String sku,
    String? barcode,
    @Default([]) List<String> imageUrls,
    required int priceCents,
    int? salePriceCents,
    @Default('') String packSize,
    @Default(0) int stockQuantity,
    int? weightGrams,
    String? supplier,
    @Default(false) bool isFeatured,
    @Default(true) bool isAvailable,
    @Default([]) List<String> tags,
    @_DtConverter() required DateTime createdAt,
    @_DtConverter() required DateTime updatedAt,
  }) = _ProductModel;

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);
}

/// Effective price in cents (sale price when active, otherwise regular price).
extension ProductModelX on ProductModel {
  int get effectivePriceCents => salePriceCents ?? priceCents;
  bool get isOnSale => salePriceCents != null && salePriceCents! < priceCents;
  String? get primaryImageUrl => imageUrls.isEmpty ? null : imageUrls.first;
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
