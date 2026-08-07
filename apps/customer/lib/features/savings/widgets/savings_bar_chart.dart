import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spazalink_core/core.dart';

import '../models/savings.dart';

/// Lightweight, dependency-free monthly savings bar chart (spec #7). Bars are
/// sized relative to the biggest month; months with no savings show an empty
/// (zero-height) bar with a R0 label.
class SavingsBarChart extends StatelessWidget {
  const SavingsBarChart({super.key, required this.months, this.height = 160});

  final List<MonthlySaving> months;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text('No savings history yet',
              style: TextStyle(color: AppColors.lightOnSurfaceVariant)),
        ),
      );
    }

    final maxCents =
        months.fold<int>(0, (m, e) => e.totalCents > m ? e.totalCents : m);

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final m in months)
            Expanded(
              child: _Bar(
                month: m,
                maxCents: maxCents,
                areaHeight: height,
              ),
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.month,
    required this.maxCents,
    required this.areaHeight,
  });

  final MonthlySaving month;
  final int maxCents;
  final double areaHeight;

  @override
  Widget build(BuildContext context) {
    // Reserve room for the two labels; the rest is the bar track.
    const labelsHeight = 34.0;
    final track = (areaHeight - labelsHeight).clamp(24.0, areaHeight);
    final frac = maxCents == 0 ? 0.0 : month.totalCents / maxCents;
    final barHeight = (frac * (track - 8)).clamp(month.totalCents > 0 ? 6.0 : 2.0, track);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            month.totalCents == 0
                ? 'R0'
                : CurrencyFormatter.format(month.totalCents),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.lightOnSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: barHeight.toDouble(),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B8F47), Color(0xFF34C471)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              color: month.totalCents == 0
                  ? AppColors.lightOutlineVariant
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('MMM').format(month.month),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.lightOnSurface,
            ),
          ),
        ],
      ),
    );
  }
}
