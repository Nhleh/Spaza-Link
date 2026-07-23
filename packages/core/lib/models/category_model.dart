import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_model.freezed.dart';
part 'category_model.g.dart';

@freezed
class CategoryModel with _$CategoryModel {
  const factory CategoryModel({
    @Default('') String id,
    required String name,
    required String slug,
    @Default('') String iconUrl,
    @Default('') String imageUrl,
    @Default(0) int sortOrder,
    @Default(true) bool isAvailable,
    @Default(0) int productCount,
    @_DtConverter() required DateTime createdAt,
  }) = _CategoryModel;

  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryModelFromJson(json);
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
