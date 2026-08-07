import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:spazalink_core/core.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/savings_repository.dart';
import '../models/savings.dart';

final savingsRepositoryProvider = Provider<SavingsRepository>((ref) {
  return SavingsRepository();
});

/// All of the signed-in customer's savings, aggregated (total/weekly/monthly/
/// history). Re-fetches whenever the auth user changes.
final savingsDataProvider = FutureProvider<SavingsData>((ref) async {
  final uid = ref.watch(authUidProvider).valueOrNull;
  if (uid == null) return SavingsData.empty;
  final entries = await ref.watch(savingsRepositoryProvider).fetchForCustomer(uid);
  return SavingsData.from(entries);
});

// ── Weekly / Monthly preference (persisted) ─────────────────────────────────

const String _kSavingsPeriodKey = 'savings_period';

class SavingsPeriodNotifier extends Notifier<SavingsPeriod> {
  Box<dynamic>? get _box => Hive.isBoxOpen(AppConstants.hiveBoxSettings)
      ? Hive.box<dynamic>(AppConstants.hiveBoxSettings)
      : null;

  @override
  SavingsPeriod build() {
    return SavingsPeriodX.fromKey(_box?.get(_kSavingsPeriodKey) as String?);
  }

  void set(SavingsPeriod period) {
    state = period;
    _box?.put(_kSavingsPeriodKey, period.storageKey);
  }
}

final savingsPeriodProvider =
    NotifierProvider<SavingsPeriodNotifier, SavingsPeriod>(
  SavingsPeriodNotifier.new,
);
