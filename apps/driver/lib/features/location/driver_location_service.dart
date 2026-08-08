import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../deliveries/providers/delivery_provider.dart';

/// Streams the driver's GPS to the backend while they have an active delivery.
/// Starts automatically the moment a job is accepted (no manual step).
class DriverLocationService {
  DriverLocationService(this._ref);
  final Ref _ref;

  StreamSubscription<Position>? _sub;
  bool get isTracking => _sub != null;

  Future<void> start() async {
    if (_sub != null) return;

    if (!await Geolocator.isLocationServiceEnabled()) return;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return;
    }

    final repo = _ref.read(driverDeliveryRepositoryProvider);

    // Immediate first fix so the admin sees the driver right away.
    try {
      final pos = await Geolocator.getCurrentPosition();
      await repo.reportLocation(pos.latitude, pos.longitude);
    } catch (_) {}

    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
      ),
    ).listen((pos) => repo.reportLocation(pos.latitude, pos.longitude));
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }
}

final driverLocationServiceProvider = Provider<DriverLocationService>((ref) {
  final service = DriverLocationService(ref);
  ref.onDispose(service.stop);
  return service;
});

/// Watch this to auto start/stop GPS based on whether the driver has an active
/// delivery. (Kept alive by the deliveries list screen.)
final locationTrackingProvider = Provider<void>((ref) {
  final service = ref.watch(driverLocationServiceProvider);
  final hasActive =
      (ref.watch(myDeliveriesProvider).valueOrNull ?? const []).isNotEmpty;
  if (hasActive) {
    service.start();
  } else {
    service.stop();
  }
});
