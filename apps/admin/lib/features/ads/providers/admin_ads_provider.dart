import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_ads_repository.dart';
import '../models/advertisement.dart';

final adminAdsRepositoryProvider =
    Provider<AdminAdsRepository>((ref) => AdminAdsRepository());

/// All advertisements for the admin list (active + inactive).
final adminAdsProvider = FutureProvider<List<Advertisement>>((ref) {
  return ref.watch(adminAdsRepositoryProvider).getAll();
});
