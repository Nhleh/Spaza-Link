import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

import '../providers/order_provider.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String _search = '';

  static const _filters = [
    (null,                       'All'),
    (OrderStatus.pending,        'Pending'),
    (OrderStatus.confirmed,      'Confirmed'),
    (OrderStatus.preparing,      'Preparing'),
    (OrderStatus.outForDelivery, 'On the Way'),
    (OrderStatus.delivered,      'Delivered'),
    (OrderStatus.cancelled,      'Cancelled'),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _filters.length, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminDarkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.adminDarkSurface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Orders',
          style: TextStyle(
            color: AppColors.darkOnSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.brandGreenPrimary,
          labelColor: AppColors.brandGreenPrimary,
          unselectedLabelColor: AppColors.darkOnSurfaceVariant,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: _filters
              .map((f) => Tab(text: f.$2))
              .toList(),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppColors.adminDarkSurface,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: const TextStyle(color: AppColors.darkOnSurface, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search by order # or shop…',
                hintStyle: const TextStyle(
                  color: AppColors.darkOnSurfaceVariant,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.darkOnSurfaceVariant,
                  size: 18,
                ),
                filled: true,
                fillColor: AppColors.adminDarkSurfaceVariant,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Tables per tab
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: _filters.map((f) => _OrdersTable(
                    statusFilter: f.$1,
                    search: _search,
                  )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Orders DataTable ──────────────────────────────────────────────────────────

class _OrdersTable extends ConsumerWidget {
  const _OrdersTable({required this.statusFilter, required this.search});

  final String? statusFilter;
  final String search;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminOrdersProvider(statusFilter));

    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.brandGreenPrimary),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Failed to load orders',
              style: TextStyle(color: AppColors.darkOnSurface),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(adminOrdersProvider(statusFilter)),
              child: const Text('Retry',
                  style: TextStyle(color: AppColors.brandGreenPrimary)),
            ),
          ],
        ),
      ),
      data: (orders) {
        final q = search.toLowerCase();
        final filtered = search.isEmpty
            ? orders
            : orders
                .where((o) =>
                    o.orderNumber.toLowerCase().contains(q) ||
                    o.shopId.toLowerCase().contains(q) ||
                    o.localUuid.toLowerCase().contains(q))
                .toList()
          ..sort((a, b) => b.placedAt.compareTo(a.placedAt));

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              search.isNotEmpty ? 'No orders match "$search"' : 'No orders.',
              style: const TextStyle(color: AppColors.darkOnSurfaceVariant),
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.brandGreenPrimary,
          onRefresh: () async =>
              ref.invalidate(adminOrdersProvider(statusFilter)),
          child: DataTable2(
            columnSpacing: 12,
            horizontalMargin: 16,
            headingRowColor: WidgetStateProperty.all(
                AppColors.adminDarkSurfaceVariant),
            dataRowColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return AppColors.brandGreenPrimary.withValues(alpha: 0.05);
              }
              return AppColors.adminDarkSurface;
            }),
            dividerThickness: 1,
            border: TableBorder(
              horizontalInside: BorderSide(
                color: AppColors.adminDarkOutline,
                width: 0.5,
              ),
            ),
            headingTextStyle: const TextStyle(
              color: AppColors.darkOnSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            dataTextStyle: const TextStyle(
              color: AppColors.darkOnSurface,
              fontSize: 12,
            ),
            columns: const [
              DataColumn2(label: Text('ORDER #'),  size: ColumnSize.M),
              DataColumn2(label: Text('DATE'),     size: ColumnSize.M),
              DataColumn2(label: Text('ITEMS'),    size: ColumnSize.S, numeric: true),
              DataColumn2(label: Text('TOTAL'),    size: ColumnSize.S, numeric: true),
              DataColumn2(label: Text('STATUS'),   size: ColumnSize.M),
              DataColumn2(label: Text('ACTIONS'),  size: ColumnSize.S, fixedWidth: 80),
            ],
            rows: filtered.map((o) => _orderRow(context, ref, o)).toList(),
          ),
        );
      },
    );
  }

  DataRow2 _orderRow(BuildContext context, WidgetRef ref, OrderModel o) {
    final id = o.id.isNotEmpty ? o.id : o.localUuid;
    final ref2 = o.orderNumber.isNotEmpty
        ? o.orderNumber
        : o.localUuid.substring(0, 8).toUpperCase();
    final color = _statusColor(o.status);

    return DataRow2(
      onTap: () => context.go(
        '${RouteConstants.adminOrders}/$id',
        extra: o,
      ),
      cells: [
        DataCell(Text(
          ref2,
          style: const TextStyle(
            fontFamily: 'monospace',
            color: AppColors.darkOnSurface,
            fontWeight: FontWeight.w600,
          ),
        )),
        DataCell(Text(_fmt(o.placedAt))),
        DataCell(Text('${o.items.length}', textAlign: TextAlign.right)),
        DataCell(Text(
          CurrencyFormatter.format(o.totalCents),
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.w600),
        )),
        DataCell(_StatusPill(status: o.status, color: color)),
        DataCell(
          IconButton(
            icon: const Icon(Icons.arrow_forward_rounded,
                size: 16, color: AppColors.darkOnSurfaceVariant),
            tooltip: 'View order',
            onPressed: () => context.go(
              '${RouteConstants.adminOrders}/$id',
              extra: o,
            ),
          ),
        ),
      ],
    );
  }

  Color _statusColor(String s) => switch (s) {
        OrderStatus.pending        => AppColors.statusPending,
        OrderStatus.confirmed      => AppColors.statusConfirmed,
        OrderStatus.preparing      => AppColors.statusPacked,
        OrderStatus.outForDelivery => AppColors.statusOutForDelivery,
        OrderStatus.delivered      => AppColors.statusDelivered,
        OrderStatus.cancelled      => AppColors.statusCancelled,
        _                          => AppColors.statusPending,
      };

  String _fmt(DateTime dt) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${m[dt.month - 1]}  $h:$min';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.color});
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
