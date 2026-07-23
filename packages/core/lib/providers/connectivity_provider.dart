import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emits the current list of connectivity results whenever the device's
/// network state changes.  `connectivity_plus` v6 returns a list because
/// a device can be on Wi-Fi AND mobile data simultaneously.
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// `true` when at least one connectivity type is available (not just 'none').
final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.when(
    data: (results) => results.any((r) => r != ConnectivityResult.none),
    loading: () => true, // Assume online until first result
    error: (_, __) => true,
  );
});
