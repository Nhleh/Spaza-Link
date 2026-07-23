import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

import '../../orders/providers/order_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../categories/providers/category_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(adminOrdersProvider(null));
    final productsAsync = ref.watch(allProductsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.adminDarkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.adminDarkSurface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: AppColors.darkOnSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              avatar: const Icon(
                Icons.circle,
                size: 8,
                color: AppColors.brandGreenPrimary,
              ),
              label: Text(
                AppConfig.instance.isDevelopment ? 'DEV' : 'PROD',
                style: const TextStyle(
                  color: AppColors.darkOnSurface,
                  fontSize: 11,
                ),
              ),
              backgroundColor: AppColors.adminDarkSurfaceVariant,
              side: const BorderSide(color: AppColors.adminDarkOutline),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.brandGreenPrimary,
        onRefresh: () async {
          ref.invalidate(adminOrdersProvider);
          ref.invalidate(allProductsProvider);
          ref.invalidate(categoriesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // ── KPI cards ──────────────────────────────────────────────────
            ordersAsync.when(
              loading: () => const _KpiShimmerRow(),
              error: (_, __) => const SizedBox.shrink(),
              data: (orders) {
                final today = DateTime.now();
                final todayOrders = orders.where((o) =>
                    o.placedAt.year == today.year &&
                    o.placedAt.month == today.month &&
                    o.placedAt.day == today.day).toList();

                final pendingCount = orders
                    .where((o) => o.status == OrderStatus.pending)
                    .length;
                final revenueToday = todayOrders.fold<int>(
                  0, (s, o) => s + o.totalCents);

                return _KpiRow(cards: [
                  _KpiData(
                    label: "Today's Orders",
                    value: '${todayOrders.length}',
                    icon: Icons.shopping_bag_outlined,
                    color: AppColors.brandGreenPrimary,
                  ),
                  _KpiData(
                    label: 'Pending',
                    value: '$pendingCount',
                    icon: Icons.hourglass_empty_rounded,
                    color: AppColors.statusPending,
                  ),
                  _KpiData(
                    label: "Revenue Today",
                    value: CurrencyFormatter.formatNoDecimals(revenueToday),
                    icon: Icons.attach_money_rounded,
                    color: AppColors.brandGold,
                  ),
                  _KpiData(
                    label: 'Total Orders',
                    value: '${orders.length}',
                    icon: Icons.receipt_long_outlined,
                    color: AppColors.statusConfirmed,
                  ),
                ]);
              },
            ),

            const SizedBox(height: 24),

            // ── Catalogue summary ──────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: productsAsync.when(
                    loading: () => const _MiniKpiShimmer(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (products) => _MiniKpiCard(
                      label: 'Products',
                      value: '${products.length}',
                      icon: Icons.inventory_2_outlined,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: categoriesAsync.when(
                    loading: () => const _MiniKpiShimmer(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (cats) => _MiniKpiCard(
                      label: 'Categories',
                      value: '${cats.length}',
                      icon: Icons.category_outlined,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ordersAsync.when(
                    loading: () => const _MiniKpiShimmer(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (orders) {
                      final delivered = orders
                          .where((o) => o.status == OrderStatus.delivered)
                          .length;
                      return _MiniKpiCard(
                        label: 'Delivered',
                        value: '$delivered',
                        icon: Icons.verified_outlined,
                        valueColor: AppColors.statusDelivered,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ordersAsync.when(
                    loading: () => const _MiniKpiShimmer(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (orders) {
                      final cancelled = orders
                          .where((o) => o.status == OrderStatus.cancelled)
                          .length;
                      return _MiniKpiCard(
                        label: 'Cancelled',
                        value: '$cancelled',
                        icon: Icons.cancel_outlined,
                        valueColor: AppColors.statusCancelled,
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Orders by status breakdown ─────────────────────────────────
            ordersAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (orders) => _StatusBreakdown(orders: orders),
            ),

            const SizedBox(height: 24),

            // ── Recent orders table ────────────────────────────────────────
            ordersAsync.when(
              loading: () => const _TableShimmer(),
              error: (e, _) => _ErrorCard(message: e.toString()),
              data: (orders) {
                final recent = [...orders]
                  ..sort((a, b) => b.placedAt.compareTo(a.placedAt));
                return _RecentOrdersTable(
                  orders: recent.take(10).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── KPI widgets ───────────────────────────────────────────────────────────────

class _KpiData {
  const _KpiData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.cards});
  final List<_KpiData> cards;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: cards
          .map((c) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: c == cards.last ? 0 : 16),
                  child: _KpiCard(data: c),
                ),
              ))
          .toList(),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});
  final _KpiData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.adminDarkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.adminDarkOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data.label,
                style: const TextStyle(
                  color: AppColors.darkOnSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(data.icon, size: 16, color: data.color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data.value,
            style: const TextStyle(
              color: AppColors.darkOnSurface,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniKpiCard extends StatelessWidget {
  const _MiniKpiCard({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.adminDarkSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.adminDarkOutline),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.darkOnSurfaceVariant),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.darkOnSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? AppColors.darkOnSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiShimmerRow extends StatelessWidget {
  const _KpiShimmerRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (i) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: i < 3 ? 16 : 0),
          child: Container(
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.adminDarkSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.adminDarkOutline),
            ),
          ),
        ),
      )),
    );
  }
}

class _MiniKpiShimmer extends StatelessWidget {
  const _MiniKpiShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.adminDarkSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.adminDarkOutline),
      ),
    );
  }
}

// ── Status breakdown ──────────────────────────────────────────────────────────

class _StatusBreakdown extends StatelessWidget {
  const _StatusBreakdown({required this.orders});
  final List<OrderModel> orders;

  static const _statuses = [
    (OrderStatus.pending,       'Pending',          AppColors.statusPending),
    (OrderStatus.confirmed,     'Confirmed',        AppColors.statusConfirmed),
    (OrderStatus.preparing,     'Preparing',        AppColors.statusPacked),
    (OrderStatus.outForDelivery,'Out for Delivery', AppColors.statusOutForDelivery),
    (OrderStatus.delivered,     'Delivered',        AppColors.statusDelivered),
    (OrderStatus.cancelled,     'Cancelled',        AppColors.statusCancelled),
  ];

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return const SizedBox.shrink();
    final total = orders.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.adminDarkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.adminDarkOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Orders by Status',
            style: TextStyle(
              color: AppColors.darkOnSurface,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ..._statuses.map((s) {
            final count = orders.where((o) => o.status == s.$1).length;
            final pct = total == 0 ? 0.0 : count / total;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      s.$2,
                      style: const TextStyle(
                        color: AppColors.darkOnSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 8,
                        backgroundColor: AppColors.adminDarkSurfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(s.$3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 32,
                    child: Text(
                      '$count',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.darkOnSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Recent orders table ───────────────────────────────────────────────────────

class _RecentOrdersTable extends StatelessWidget {
  const _RecentOrdersTable({required this.orders});
  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.adminDarkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.adminDarkOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Orders',
                  style: TextStyle(
                    color: AppColors.darkOnSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(RouteConstants.adminOrders),
                  child: const Text(
                    'View all',
                    style: TextStyle(
                      color: AppColors.brandGreenPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.adminDarkOutline, height: 1),
          if (orders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No orders yet.',
                  style: TextStyle(color: AppColors.darkOnSurfaceVariant),
                ),
              ),
            )
          else
            ...orders.map((o) => _OrderRow(order: o)),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});
  final OrderModel order;

  static const _statusColors = {
    OrderStatus.pending:        AppColors.statusPending,
    OrderStatus.confirmed:      AppColors.statusConfirmed,
    OrderStatus.preparing:      AppColors.statusPacked,
    OrderStatus.outForDelivery: AppColors.statusOutForDelivery,
    OrderStatus.delivered:      AppColors.statusDelivered,
    OrderStatus.cancelled:      AppColors.statusCancelled,
  };

  @override
  Widget build(BuildContext context) {
    final color = _statusColors[order.status] ?? AppColors.statusPending;
    final ref = order.orderNumber.isNotEmpty
        ? order.orderNumber
        : order.localUuid.substring(0, 8).toUpperCase();

    return InkWell(
      onTap: () {
        final id = order.id.isNotEmpty ? order.id : order.localUuid;
        context.go('${RouteConstants.adminOrders}/$id', extra: order);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Ref
            SizedBox(
              width: 140,
              child: Text(
                ref,
                style: const TextStyle(
                  color: AppColors.darkOnSurface,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Date
            Expanded(
              child: Text(
                _fmt(order.placedAt),
                style: const TextStyle(
                  color: AppColors.darkOnSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
            // Total
            SizedBox(
              width: 90,
              child: Text(
                CurrencyFormatter.format(order.totalCents),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.darkOnSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Status chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                order.status.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${m[dt.month - 1]}  $h:$min';
  }
}

class _TableShimmer extends StatelessWidget {
  const _TableShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.adminDarkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.adminDarkOutline),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.error, fontSize: 13),
      ),
    );
  }
}
