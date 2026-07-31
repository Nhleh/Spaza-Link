// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

import '../../categories/providers/category_provider.dart';
import '../../orders/providers/order_provider.dart';
import '../../products/providers/product_provider.dart';

/// Live reports computed from the Supabase orders/products/categories.
class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  static const _statusOrder = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.preparing,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
    OrderStatus.cancelled,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(adminOrdersProvider(null));
    final products = ref.watch(allProductsProvider).valueOrNull ?? const [];
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];

    return Scaffold(
      backgroundColor: AppColors.adminDarkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.adminDarkSurface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Reports',
            style: TextStyle(
                color: AppColors.darkOnSurface, fontWeight: FontWeight.w700)),
        actions: [
          TextButton.icon(
            onPressed: () => _downloadPdf(context, ref),
            icon: const Icon(Icons.download_rounded,
                size: 18, color: AppColors.brandGreenPrimary),
            label: const Text('Download PDF',
                style: TextStyle(color: AppColors.brandGreenPrimary)),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.darkOnSurface),
            onPressed: () => ref.invalidate(adminOrdersProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ordersAsync.when(
        loading: () => const Center(
            child:
                CircularProgressIndicator(color: AppColors.brandGreenPrimary)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load reports.\n$e',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: AppColors.darkOnSurfaceVariant)),
          ),
        ),
        data: (orders) {
          final active =
              orders.where((o) => o.status != OrderStatus.cancelled).toList();
          final revenue = active.fold<int>(0, (s, o) => s + o.totalCents);
          final aov =
              active.isEmpty ? 0 : (revenue / active.length).round();
          // Profit = the 15% markup portion of what customers paid
          // (customer price = base × 1.15, so profit = revenue × 0.15/1.15).
          final profit = (revenue *
                  AppConstants.productMarkup /
                  (1 + AppConstants.productMarkup))
              .round();
          final byStatus = <String, int>{};
          for (final o in orders) {
            byStatus[o.status] = (byStatus[o.status] ?? 0) + 1;
          }
          final recent = [...orders]
            ..sort((a, b) => b.placedAt.compareTo(a.placedAt));

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _kpi('Total orders', '${orders.length}',
                      Icons.receipt_long_rounded),
                  _kpi('Revenue', CurrencyFormatter.formatNoDecimals(revenue),
                      Icons.payments_rounded),
                  _kpi('Profit (15%)',
                      CurrencyFormatter.formatNoDecimals(profit),
                      Icons.savings_rounded,
                      highlight: true),
                  _kpi('Avg order value',
                      CurrencyFormatter.formatNoDecimals(aov),
                      Icons.trending_up_rounded),
                  _kpi('Products', '${products.length}',
                      Icons.inventory_2_rounded),
                  _kpi('Categories', '${categories.length}',
                      Icons.category_rounded),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(builder: (context, c) {
                final revenueCard = _card('Revenue — last 7 days',
                    SizedBox(height: 220, child: _RevenueChart(orders: orders)));
                final statusCard = _card('Order status split',
                    SizedBox(height: 220, child: _StatusPie(byStatus: byStatus)));
                if (c.maxWidth > 720) {
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: revenueCard),
                        const SizedBox(width: 16),
                        Expanded(child: statusCard),
                      ],
                    ),
                  );
                }
                return Column(children: [
                  revenueCard,
                  const SizedBox(height: 16),
                  statusCard,
                ]);
              }),
              const SizedBox(height: 16),
              _card(
                'Orders by status',
                Column(
                  children: [
                    for (final s in _statusOrder)
                      _statusRow(s, byStatus[s] ?? 0, orders.length),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _card(
                'Recent orders',
                Column(
                  children: [
                    if (recent.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('No orders yet.',
                            style: TextStyle(
                                color: AppColors.darkOnSurfaceVariant)),
                      )
                    else
                      for (final o in recent.take(8))
                        _RecentOrderRow(order: o),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _kpi(String label, String value, IconData icon,
          {bool highlight = false}) =>
      Container(
        width: 200,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: highlight
              ? AppColors.brandGreenPrimary.withValues(alpha: 0.12)
              : AppColors.adminDarkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: highlight
                  ? AppColors.brandGreenPrimary.withValues(alpha: 0.5)
                  : AppColors.adminDarkOutline,
              width: highlight ? 1 : 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.brandGreenPrimary, size: 22),
            const SizedBox(height: 12),
            Text(value,
                style: const TextStyle(
                    color: AppColors.darkOnSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: AppColors.darkOnSurfaceVariant, fontSize: 12.5)),
          ],
        ),
      );

  Widget _card(String title, Widget child) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.adminDarkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.adminDarkOutline, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.toUpperCase(),
                style: const TextStyle(
                    color: AppColors.darkOnSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6)),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );

  Widget _statusRow(String status, int count, int total) {
    final pct = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_statusLabel(status),
                    style: const TextStyle(
                        color: AppColors.darkOnSurface, fontSize: 13)),
              ),
              Text('$count',
                  style: const TextStyle(
                      color: AppColors.darkOnSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: AppColors.adminDarkSurfaceVariant,
              valueColor: AlwaysStoppedAnimation(_statusColor(status)),
            ),
          ),
        ],
      ),
    );
  }

  static String _statusLabel(String s) => switch (s) {
        OrderStatus.pending => 'Pending',
        OrderStatus.confirmed => 'Confirmed',
        OrderStatus.preparing => 'Preparing',
        OrderStatus.outForDelivery => 'Out for delivery',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Cancelled',
        _ => s,
      };

  static Color _statusColor(String s) => switch (s) {
        OrderStatus.delivered => AppColors.statusDelivered,
        OrderStatus.cancelled => AppColors.error,
        OrderStatus.pending => AppColors.brandGold,
        _ => AppColors.brandGreenPrimary,
      };

  // ── PDF export via the browser's print-to-PDF (no plugin needed) ──────────
  void _downloadPdf(BuildContext context, WidgetRef ref) {
    final orders = ref.read(adminOrdersProvider(null)).valueOrNull ?? const [];
    final products = ref.read(allProductsProvider).valueOrNull ?? const [];
    final categories = ref.read(categoriesProvider).valueOrNull ?? const [];
    if (orders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data to export yet.')));
      return;
    }
    final htmlStr = _reportHtml(orders, products.length, categories.length);
    final blob = html.Blob([htmlStr], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    // Opens a print-ready report in a new tab; it auto-triggers the browser's
    // print dialog, where the user chooses "Save as PDF".
    html.window.open(url, '_blank');
  }

  String _reportHtml(List<OrderModel> orders, int productCount, int catCount) {
    final active =
        orders.where((o) => o.status != OrderStatus.cancelled).toList();
    final revenue = active.fold<int>(0, (s, o) => s + o.totalCents);
    final aov = active.isEmpty ? 0 : (revenue / active.length).round();
    final profit = (revenue *
            AppConstants.productMarkup /
            (1 + AppConstants.productMarkup))
        .round();
    final byStatus = <String, int>{};
    for (final o in orders) {
      byStatus[o.status] = (byStatus[o.status] ?? 0) + 1;
    }
    final recent = [...orders]
      ..sort((a, b) => b.placedAt.compareTo(a.placedAt));

    final statusRows = StringBuffer();
    for (final s in _statusOrder) {
      statusRows.write(
          '<tr><td>${_statusLabel(s)}</td><td class="r">${byStatus[s] ?? 0}</td></tr>');
    }
    final recentRows = StringBuffer();
    for (final o in recent.take(30)) {
      final r = o.id.split('-').first.toUpperCase();
      recentRows.write('<tr><td>#$r</td><td>${_fmtDate(o.placedAt)}</td>'
          '<td>${_statusLabel(o.status)}</td>'
          '<td class="r">${CurrencyFormatter.format(o.totalCents)}</td></tr>');
    }

    return '''
<!doctype html><html><head><meta charset="utf-8"><title>SpazaLink Report</title>
<style>
 body{font-family:Arial,Helvetica,sans-serif;color:#12211a;margin:32px;}
 h1{color:#1B5E20;margin:0 0 2px;font-size:22px;}
 h3{margin:22px 0 8px;font-size:14px;}
 .sub{color:#777;margin:0 0 20px;font-size:12px;}
 .kpis{display:flex;flex-wrap:wrap;gap:10px;margin-bottom:8px;}
 .kpi{border:1px solid #ddd;border-radius:8px;padding:10px 14px;min-width:120px;}
 .kpi .v{font-size:20px;font-weight:800;}
 .kpi .l{font-size:11px;color:#777;}
 table{width:100%;border-collapse:collapse;}
 th,td{text-align:left;padding:7px 8px;border-bottom:1px solid #eee;font-size:12.5px;}
 th{color:#777;font-size:10.5px;text-transform:uppercase;letter-spacing:.5px;}
 .r{text-align:right;}
 @media print{body{margin:10px;}}
</style></head><body>
<h1>SpazaLink &mdash; Business Report</h1>
<p class="sub">Generated ${_fmtDate(DateTime.now())}</p>
<div class="kpis">
 <div class="kpi"><div class="v">${orders.length}</div><div class="l">Total orders</div></div>
 <div class="kpi"><div class="v">${CurrencyFormatter.format(revenue)}</div><div class="l">Revenue</div></div>
 <div class="kpi" style="border-color:#1B5E20;background:#f1f8f2"><div class="v" style="color:#1B5E20">${CurrencyFormatter.format(profit)}</div><div class="l">Profit (15% markup)</div></div>
 <div class="kpi"><div class="v">${CurrencyFormatter.format(aov)}</div><div class="l">Avg order value</div></div>
 <div class="kpi"><div class="v">$productCount</div><div class="l">Products</div></div>
 <div class="kpi"><div class="v">$catCount</div><div class="l">Categories</div></div>
</div>
<h3>Orders by status</h3>
<table><thead><tr><th>Status</th><th class="r">Count</th></tr></thead><tbody>$statusRows</tbody></table>
<h3>Recent orders</h3>
<table><thead><tr><th>Ref</th><th>Date</th><th>Status</th><th class="r">Total</th></tr></thead><tbody>$recentRows</tbody></table>
<script>window.onload=function(){setTimeout(function(){window.print();},350);};</script>
</body></html>
''';
  }

  static String _fmtDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _RecentOrderRow extends StatelessWidget {
  const _RecentOrderRow({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final ref = order.id.split('-').first.toUpperCase();
    return InkWell(
      onTap: () => context.go('${RouteConstants.adminOrders}/${order.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#$ref',
                      style: const TextStyle(
                          color: AppColors.darkOnSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(_fmt(order.placedAt),
                      style: const TextStyle(
                          color: AppColors.darkOnSurfaceVariant, fontSize: 11.5)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AdminReportsScreen._statusColor(order.status)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(AdminReportsScreen._statusLabel(order.status),
                  style: TextStyle(
                      color: AdminReportsScreen._statusColor(order.status),
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Text(CurrencyFormatter.format(order.totalCents),
                style: const TextStyle(
                    color: AppColors.darkOnSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

/// Bar chart of revenue for each of the last 7 days.
class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.orders});
  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final daily = <double>[
      for (final day in days)
        orders
                .where((o) =>
                    o.status != OrderStatus.cancelled && _sameDay(o.placedAt, day))
                .fold<int>(0, (s, o) => s + o.totalCents) /
            100.0,
    ];
    final maxV = daily.fold<double>(0, (m, v) => v > m ? v : m);
    final maxY = maxV <= 0 ? 100.0 : maxV * 1.25;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
              'R${rod.toY.toStringAsFixed(0)}',
              const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (v, meta) => Text('R${v.toInt()}',
                  style: const TextStyle(
                      color: AppColors.darkOnSurfaceVariant, fontSize: 9)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                final label = (i >= 0 && i < days.length)
                    ? '${days[i].day}/${days[i].month}'
                    : '';
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(label,
                      style: const TextStyle(
                          color: AppColors.darkOnSurfaceVariant, fontSize: 9)),
                );
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => const FlLine(
              color: AppColors.adminDarkOutline, strokeWidth: 0.4),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (int i = 0; i < daily.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: daily[i],
                width: 16,
                color: AppColors.brandGreenPrimary,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ]),
        ],
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Pie chart of the order-status distribution, with a legend.
class _StatusPie extends StatelessWidget {
  const _StatusPie({required this.byStatus});
  final Map<String, int> byStatus;

  @override
  Widget build(BuildContext context) {
    final entries = AdminReportsScreen._statusOrder
        .where((s) => (byStatus[s] ?? 0) > 0)
        .toList();
    final total = byStatus.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      return const Center(
        child: Text('No orders yet.',
            style: TextStyle(color: AppColors.darkOnSurfaceVariant)),
      );
    }
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              sections: [
                for (final s in entries)
                  PieChartSectionData(
                    value: (byStatus[s] ?? 0).toDouble(),
                    color: AdminReportsScreen._statusColor(s),
                    title: '${byStatus[s]}',
                    radius: 50,
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final s in entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: AdminReportsScreen._statusColor(s),
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(AdminReportsScreen._statusLabel(s),
                          style: const TextStyle(
                              color: AppColors.darkOnSurface, fontSize: 11),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
