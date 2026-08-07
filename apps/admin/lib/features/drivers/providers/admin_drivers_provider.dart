import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_drivers_repository.dart';

final adminDriversRepositoryProvider =
    Provider<AdminDriversRepository>((ref) => AdminDriversRepository());

/// All active drivers (for the list + the assign picker).
final adminDriversProvider = FutureProvider<List<DriverInfo>>((ref) {
  return ref.watch(adminDriversRepositoryProvider).listDrivers();
});
