import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String uid,
    required String phoneNumber,
    @Default('') String displayName,
    String? email,
    @Default('customer') String role,
    @Default(true) bool isActive,
    @_DateTimeConverter() required DateTime createdAt,
    @_DateTimeConverter() required DateTime updatedAt,
    @Default([]) List<String> fcmTokens,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

/// Serialises DateTime as milliseconds-since-epoch int.
/// The Firestore repository converts Timestamp ↔ DateTime before calling fromJson.
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
