/// Which savings window the main dashboard card shows (spec #4).
enum SavingsPeriod { weekly, monthly }

extension SavingsPeriodX on SavingsPeriod {
  String get storageKey => name; // 'weekly' | 'monthly'
  String get label => this == SavingsPeriod.weekly ? 'Weekly' : 'Monthly';

  static SavingsPeriod fromKey(String? key) =>
      key == SavingsPeriod.monthly.name
          ? SavingsPeriod.monthly
          : SavingsPeriod.weekly;
}

/// One order's savings, split into the three categories (spec #6).
class SavingEntry {
  const SavingEntry({
    required this.date,
    required this.discountCents,
    required this.poolCents,
    required this.deliveryCents,
  });

  final DateTime date;
  final int discountCents;
  final int poolCents;
  final int deliveryCents;

  int get totalCents => discountCents + poolCents + deliveryCents;

  factory SavingEntry.fromRow(Map<String, dynamic> r) {
    int c(String k) => (r[k] as num?)?.toInt() ?? 0;
    final raw = r['created_at'];
    final date = raw == null
        ? DateTime.now()
        : DateTime.tryParse(raw.toString())?.toLocal() ?? DateTime.now();
    return SavingEntry(
      date: date,
      discountCents: c('discount_saved_cents'),
      poolCents: c('pool_saved_cents'),
      deliveryCents: c('delivery_saved_cents'),
    );
  }
}

/// Aggregated totals for a set of [SavingEntry]s.
class SavingsSummary {
  const SavingsSummary({
    this.discountCents = 0,
    this.poolCents = 0,
    this.deliveryCents = 0,
  });

  final int discountCents;
  final int poolCents;
  final int deliveryCents;

  int get totalCents => discountCents + poolCents + deliveryCents;
  bool get isEmpty => totalCents == 0;

  static SavingsSummary of(Iterable<SavingEntry> entries) {
    var d = 0, p = 0, del = 0;
    for (final e in entries) {
      d += e.discountCents;
      p += e.poolCents;
      del += e.deliveryCents;
    }
    return SavingsSummary(discountCents: d, poolCents: p, deliveryCents: del);
  }
}

/// One point on the monthly savings graph (spec #7).
class MonthlySaving {
  const MonthlySaving({required this.month, required this.totalCents});

  /// First day of the month this bar represents.
  final DateTime month;
  final int totalCents;
}

/// Everything the Savings card + report need, computed once from the raw rows.
class SavingsData {
  const SavingsData({
    required this.entries,
    required this.total,
    required this.weekly,
    required this.monthly,
    required this.history,
  });

  final List<SavingEntry> entries;
  final SavingsSummary total;
  final SavingsSummary weekly;
  final SavingsSummary monthly;

  /// Last 6 months oldest → newest (zero-filled).
  final List<MonthlySaving> history;

  bool get hasAny => total.totalCents > 0;

  factory SavingsData.from(List<SavingEntry> entries) {
    final now = DateTime.now();
    // Monday as the start of the week.
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month);

    final weekly = SavingsSummary.of(
        entries.where((e) => !e.date.isBefore(startOfWeek)));
    final monthly = SavingsSummary.of(
        entries.where((e) => !e.date.isBefore(startOfMonth)));

    // 6-month zero-filled history.
    final history = <MonthlySaving>[];
    for (var i = 5; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i);
      final next = DateTime(now.year, now.month - i + 1);
      final sum = entries
          .where((e) => !e.date.isBefore(m) && e.date.isBefore(next))
          .fold<int>(0, (s, e) => s + e.totalCents);
      history.add(MonthlySaving(month: m, totalCents: sum));
    }

    return SavingsData(
      entries: entries,
      total: SavingsSummary.of(entries),
      weekly: weekly,
      monthly: monthly,
      history: history,
    );
  }

  static const empty = SavingsData(
    entries: [],
    total: SavingsSummary(),
    weekly: SavingsSummary(),
    monthly: SavingsSummary(),
    history: [],
  );
}
