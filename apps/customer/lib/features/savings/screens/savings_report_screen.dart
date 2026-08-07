import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:spazalink_core/core.dart';

import '../models/savings.dart';
import '../providers/savings_provider.dart';
import '../widgets/savings_bar_chart.dart';

/// Detailed Savings Report (spec #5–#7): total, weekly, monthly, category
/// breakdown, monthly graph and savings history.
class SavingsReportScreen extends ConsumerWidget {
  const SavingsReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(savingsDataProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Savings Report',
            style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.brandGreenPrimary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.brandGreenPrimary)),
        error: (_, __) => Center(
          child: EmptyStateWidget(
            type: EmptyStateType.error,
            message: 'Could not load your savings.',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(savingsDataProvider),
          ),
        ),
        data: (data) => RefreshIndicator(
          color: AppColors.brandGreenPrimary,
          onRefresh: () async => ref.invalidate(savingsDataProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPaddingH,
              AppSpacing.lg,
              AppSpacing.screenPaddingH,
              AppSpacing.x4l,
            ),
            children: [
              _TotalCard(cents: data.total.totalCents),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                        label: 'This week', cents: data.weekly.totalCents),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _MiniStat(
                        label: 'This month', cents: data.monthly.totalCents),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _SectionTitle('Monthly savings'),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: _cardDecoration,
                child: SavingsBarChart(months: data.history),
              ),
              const SizedBox(height: AppSpacing.xl),
              _SectionTitle('How you saved'),
              const SizedBox(height: AppSpacing.md),
              _BreakdownRow(
                icon: Icons.local_offer_rounded,
                label: 'Special discount savings',
                subtitle: 'Buying discounted products',
                cents: data.total.discountCents,
                color: AppColors.brandGold,
              ),
              _BreakdownRow(
                icon: Icons.groups_rounded,
                label: 'Pool buying savings',
                subtitle: 'Joining buying pools',
                cents: data.total.poolCents,
                color: AppColors.brandGreenPrimary,
              ),
              _BreakdownRow(
                icon: Icons.local_shipping_rounded,
                label: 'Delivery savings',
                subtitle: 'Free-delivery orders',
                cents: data.total.deliveryCents,
                color: AppColors.brandGreenMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              _SectionTitle('Savings history'),
              const SizedBox(height: AppSpacing.md),
              if (data.entries.where((e) => e.totalCents > 0).isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: _cardDecoration,
                  child: const Center(
                    child: Text(
                      'No savings yet. Buy discounted products, join a buying '
                      'pool, or qualify for free delivery to start saving.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.lightOnSurfaceVariant),
                    ),
                  ),
                )
              else
                Container(
                  decoration: _cardDecoration,
                  child: Column(
                    children: [
                      for (final e
                          in data.entries.where((e) => e.totalCents > 0))
                        _HistoryRow(entry: e),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

final _cardDecoration = BoxDecoration(
  color: AppColors.lightSurface,
  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
  border: Border.all(color: AppColors.lightOutlineVariant),
);

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.cents});
  final int cents;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl, vertical: AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF066837), Color(0xFF0B8F47)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total savings',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.white.withValues(alpha: 0.9))),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(cents),
            style: AppTypography.headlineLarge.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.cents});
  final String label;
  final int cents;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.lightOnSurfaceVariant)),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(cents),
            style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800, color: AppColors.lightOnSurface),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700));
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.cents,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final int cents;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTypography.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.lightOnSurfaceVariant)),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(cents),
            style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w800, color: AppColors.lightOnSurface),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});
  final SavingEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.savings_rounded,
              color: AppColors.brandGreenPrimary, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              DateFormat('EEE, d MMM yyyy').format(entry.date),
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.lightOnSurface),
            ),
          ),
          Text(
            CurrencyFormatter.format(entry.totalCents),
            style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.brandGreenPrimary),
          ),
        ],
      ),
    );
  }
}
