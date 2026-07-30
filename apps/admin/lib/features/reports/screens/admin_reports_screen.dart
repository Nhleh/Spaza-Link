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

  Widget _kpi(String label, String value, IconData icon) => Container(
        width: 200,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.adminDarkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.adminDarkOutline, width: 0.5),
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
