import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';

import '../providers/order_provider.dart';

class AdminOrderDetailScreen extends ConsumerStatefulWidget {
  const AdminOrderDetailScreen({
    super.key,
    required this.orderId,
    this.order,
  });

  final String orderId;
  final OrderModel? order;

  @override
  ConsumerState<AdminOrderDetailScreen> createState() =>
      _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState
    extends ConsumerState<AdminOrderDetailScreen> {
  String? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminOrderDetailProvider(widget.orderId));
    final o = async.valueOrNull ?? widget.order;
    final actionState = ref.watch(orderActionProvider);
    final isLoading = actionState is OrderActionLoading;

    // Show snackbar on action result
    ref.listen<OrderActionState>(orderActionProvider, (_, next) {
      if (next is OrderActionSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order updated.'),
            backgroundColor: AppColors.brandGreenPrimary,
          ),
        );
        ref.invalidate(adminOrderDetailProvider(widget.orderId));
        ref.invalidate(adminOrdersProvider(null));
        ref.read(orderActionProvider.notifier).reset();
      } else if (next is OrderActionError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(orderActionProvider.notifier).reset();
      }
    });

    if (o == null) {
      return Scaffold(
        backgroundColor: AppColors.adminDarkBackground,
        appBar: AppBar(
          backgroundColor: AppColors.adminDarkSurface,
          title: Text(
            widget.orderId,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.brandGreenPrimary),
        ),
      );
    }

    _selectedStatus ??= o.status;

    final displayRef =
        o.orderNumber.isNotEmpty ? o.orderNumber : o.localUuid;

    return Scaffold(
      backgroundColor: AppColors.adminDarkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.adminDarkSurface,
        elevation: 0,
        title: Text(
          displayRef,
          style: const TextStyle(
            color: AppColors.darkOnSurface,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
            fontSize: 15,
          ),
        ),
        actions: [
          // Status dropdown + update button
          Row(
            children: [
              _StatusDropdown(
                value: _selectedStatus!,
                onChanged: (v) => setState(() => _selectedStatus = v),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: isLoading || _selectedStatus == o.status
                    ? null
                    : () => ref
                        .read(orderActionProvider.notifier)
                        .updateStatus(orderId: o.id, status: _selectedStatus!),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandGreenPrimary,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor:
                      AppColors.adminDarkSurfaceVariant,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('Update',
                        style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Two-column layout ──────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    // Items card
                    _AdminCard(
                      title: 'Items (${o.items.length})',
                      child: Column(
                        children: [
                          // Header
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'PRODUCT',
                                    style: TextStyle(
                                      color: AppColors.darkOnSurfaceVariant,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 50,
                                  child: Text(
                                    'QTY',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: AppColors.darkOnSurfaceVariant,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    'TOTAL',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: AppColors.darkOnSurfaceVariant,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(color: AppColors.adminDarkOutline),
                          ...o.items.map((item) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.productName,
                                            style: const TextStyle(
                                              color: AppColors.darkOnSurface,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (item.packSize.isNotEmpty)
                                            Text(
                                              item.packSize,
                                              style: const TextStyle(
                                                color: AppColors
                                                    .darkOnSurfaceVariant,
                                                fontSize: 11,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 50,
                                      child: Text(
                                        '×${item.quantity}',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          color: AppColors.darkOnSurfaceVariant,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 80,
                                      child: Text(
                                        CurrencyFormatter.format(
                                            item.lineTotalCents),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          color: AppColors.darkOnSurface,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                          const Divider(color: AppColors.adminDarkOutline),
                          _TotalRow(label: 'Subtotal',
                              value: CurrencyFormatter.format(o.subtotalCents)),
                          if (o.deliveryFeeCents > 0)
                            _TotalRow(
                              label: 'Delivery',
                              value: CurrencyFormatter.format(
                                  o.deliveryFeeCents),
                            ),
                          if (o.discountAmountCents > 0)
                            _TotalRow(
                              label: 'Discount',
                              value: '−${CurrencyFormatter.format(o.discountAmountCents)}',
                              valueColor: AppColors.brandGreenPrimary,
                            ),
                          const Divider(color: AppColors.adminDarkOutline),
                          _TotalRow(
                            label: 'Total',
                            value: CurrencyFormatter.format(o.totalCents),
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // Right column
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    // Order info
                    _AdminCard(
                      title: 'Order Info',
                      child: Column(
                        children: [
                          _InfoRow(label: 'Order ref',
                              value: displayRef,
                              mono: true),
                          _InfoRow(label: 'Shop ID',
                              value: o.shopId,
                              mono: true),
                          _InfoRow(label: 'Customer ID',
                              value: o.customerId,
                              mono: true),
                          _InfoRow(
                              label: 'Placed',
                              value: _fmt(o.placedAt)),
                          _InfoRow(
                              label: 'Sync',
                              value: o.syncStatus,
                              valueColor: o.syncStatus == SyncStatus.synced
                                  ? AppColors.statusDelivered
                                  : AppColors.syncPending),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Delivery
                    _AdminCard(
                      title: 'Delivery',
                      child: Column(
                        children: [
                          _InfoRow(
                              label: 'Address',
                              value: o.deliveryAddress),
                          if (o.notes?.isNotEmpty == true)
                            _InfoRow(label: 'Notes', value: o.notes!),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Payment
                    _AdminCard(
                      title: 'Payment',
                      child: Column(
                        children: [
                          _InfoRow(
                              label: 'Method',
                              value: _methodLabel(o.paymentMethod)),
                          _InfoRow(
                              label: 'Status',
                              value: o.paymentStatus.toUpperCase(),
                              valueColor: o.paymentStatus == PaymentStatus.paid
                                  ? AppColors.statusDelivered
                                  : AppColors.darkOnSurface),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}  $h:$min';
  }

  String _methodLabel(String m) => switch (m) {
        PaymentMethod.cod     => 'Cash on Delivery',
        PaymentMethod.payfast => 'PayFast',
        PaymentMethod.ozow    => 'Ozow EFT',
        PaymentMethod.yoco    => 'Yoco Card',
        _                     => m,
      };
}

// ── Shared admin sub-widgets ──────────────────────────────────────────────────

class _AdminCard extends StatelessWidget {
  const _AdminCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.adminDarkSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.adminDarkOutline),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.darkOnSurface,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.adminDarkOutline, height: 1),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.darkOnSurfaceVariant,
              fontSize: 12,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.darkOnSurface,
              fontSize: 12,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.mono = false,
    this.valueColor,
  });
  final String label;
  final String value;
  final bool mono;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.darkOnSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppColors.darkOnSurface,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  static const _options = [
    (OrderStatus.pending,        'Pending'),
    (OrderStatus.confirmed,      'Confirmed'),
    (OrderStatus.preparing,      'Preparing'),
    (OrderStatus.outForDelivery, 'Out for Delivery'),
    (OrderStatus.delivered,      'Delivered'),
    (OrderStatus.cancelled,      'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.adminDarkSurfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.adminDarkOutline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: AppColors.adminDarkSurface,
          style: const TextStyle(
            color: AppColors.darkOnSurface,
            fontSize: 13,
          ),
          items: _options
              .map((o) => DropdownMenuItem(
                    value: o.$1,
                    child: Text(o.$2),
                  ))
              .toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }
}
