import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ads_repository.dart';
import '../models/advertisement.dart';

final adsRepositoryProvider = Provider<AdsRepository>((ref) => AdsRepository());

/// Currently-active advertisements for the Shop banner. Empty list → the banner
/// is hidden (spec #9). Errors degrade to an empty list so the Shop never
/// breaks because of ads.
final activeAdsProvider = FutureProvider<List<AdvertisementModel>>((ref) async {
  try {
    return await ref.watch(adsRepositoryProvider).fetchActive();
  } catch (_) {
    return const <AdvertisementModel>[];
  }
});
