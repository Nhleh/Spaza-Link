import 'package:freezed_annotation/freezed_annotation.dart';

part 'gps_location.freezed.dart';
part 'gps_location.g.dart';

/// A WGS-84 coordinate pair.
///
/// Named [GpsLocation] rather than LatLng to avoid collision with
/// google_maps_flutter's LatLng in apps that use both.
@freezed
class GpsLocation with _$GpsLocation {
  const factory GpsLocation({
    required double latitude,
    required double longitude,
  }) = _GpsLocation;

  factory GpsLocation.fromJson(Map<String, dynamic> json) =>
      _$GpsLocationFromJson(json);
}
