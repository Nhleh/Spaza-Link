import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';

import '../../drivers/data/admin_drivers_repository.dart';
import '../../drivers/providers/admin_drivers_provider.dart';
import '../../drivers/widgets/pod_card.dart';
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
                          _InfoRow(
                              label: 'Order status',
                              value: o.status.toUpperCase(),
                              valueColor: o.status == OrderStatus.cancelled
                                  ? AppColors.error
                                  : o.status == OrderStatus.pending
                                      ? AppColors.brandGold
                                      : AppColors.brandGreenPrimary),
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _InfoRow(
                              label: 'Address',
                              value: o.deliveryAddress),
                          if (o.notes?.isNotEmpty == true)
                            _InfoRow(label: 'Notes', value: o.notes!),
                          const SizedBox(height: 12),
                          _AssignDriverButton(order: o),
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
                              label: 'Payment status',
                              value: o.paymentStatus.toUpperCase(),
                              valueColor: o.paymentStatus == PaymentStatus.paid
                                  ? AppColors.statusDelivered
                                  : AppColors.darkOnSurface),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Proof of delivery (signed slip + PDF download)
                    PodCard(orderId: o.id, orderRef: displayRef),
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

// ── Assign to driver ──────────────────────────────────────────────────────────

class _AssignDriverButton extends StatelessWidget {
  const _AssignDriverButton({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final assigned = order.driverId != null && order.driverId!.isNotEmpty;
    return OutlinedButton.icon(
      onPressed: () => showDialog(
        context: context,
        builder: (_) => _AssignDialog(order: order),
      ),
      icon: const Icon(Icons.delivery_dining_rounded, size: 16),
      label: Text(assigned ? 'Reassign driver' : 'Assign driver',
          style: const TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.brandGreenPrimary,
        side: const BorderSide(color: AppColors.brandGreenPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _AssignDialog extends ConsumerStatefulWidget {
  const _AssignDialog({required this.order});
  final OrderModel order;

  @override
  ConsumerState<_AssignDialog> createState() => _AssignDialogState();
}

class _AssignDialogState extends ConsumerState<_AssignDialog> {
  String? _driverId;
  final _pickup = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _driverId = (widget.order.driverId?.isNotEmpty ?? false)
        ? widget.order.driverId
        : null;
  }

  @override
  void dispose() {
    _pickup.dispose();
    super.dispose();
  }

  Future<void> _assign() async {
    if (_driverId == null) {
      _snack('Pick a driver.', error: true);
      return;
    }
    if (_pickup.text.trim().isEmpty) {
      _snack('Enter the pickup location.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(adminDriversRepositoryProvider).assignOrder(
            orderId: widget.order.id,
            driverId: _driverId!,
            pickupAddress: _pickup.text,
          );
      if (!mounted) return;
      ref.invalidate(adminOrderDetailProvider(widget.order.id));
      ref.invalidate(adminOrdersProvider(null));
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Order assigned to driver.'),
        backgroundColor: AppColors.brandGreenPrimary,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Assign failed: $e', error: true);
    }
  }

  void _snack(String m, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m),
        backgroundColor: error ? AppColors.error : AppColors.brandGreenPrimary,
      ));

  @override
  Widget build(BuildContext context) {
    final driversAsync = ref.watch(adminDriversProvider);
    return AlertDialog(
      backgroundColor: AppColors.adminDarkSurface,
      title: const Text('Assign delivery',
          style: TextStyle(color: AppColors.darkOnSurface)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Driver',
                style: TextStyle(color: AppColors.darkOnSurfaceVariant, fontSize: 12)),
            const SizedBox(height: 6),
            driversAsync.when(
              loading: () => const LinearProgressIndicator(
                  color: AppColors.brandGreenPrimary),
              error: (e, _) => const Text('Could not load drivers',
                  style: TextStyle(color: AppColors.error)),
              data: (drivers) {
                if (drivers.isEmpty) {
                  return const Text(
                    'No drivers yet — add one on the Drivers page first.',
                    style: TextStyle(color: AppColors.darkOnSurfaceVariant),
                  );
                }
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.darkOutline),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _driverId,
                      isExpanded: true,
                      dropdownColor: AppColors.adminDarkSurface,
                      hint: const Text('Select a driver',
                          style: TextStyle(color: AppColors.darkOnSurfaceVariant)),
                      style: const TextStyle(color: AppColors.darkOnSurface),
                      items: [
                        for (final DriverInfo d in drivers)
                          DropdownMenuItem(
                            value: d.id,
                            child: Text(d.phone.isEmpty
                                ? d.name
                                : '${d.name} · ${d.phone}'),
                          ),
                      ],
                      onChanged: (v) => setState(() => _driverId = v),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            const Text('Pickup location',
                style: TextStyle(color: AppColors.darkOnSurfaceVariant, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: _pickup,
              style: const TextStyle(color: AppColors.darkOnSurface),
              decoration: InputDecoration(
                hintText: 'Where the driver collects the order',
                hintStyle: const TextStyle(color: AppColors.darkOnSurfaceVariant),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.darkOutline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.brandGreenPrimary),
                ),
              ),
            ),
            if (widget.order.deliveryAddress.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Delivery to: ${widget.order.deliveryAddress}',
                  style: const TextStyle(
                      color: AppColors.darkOnSurfaceVariant, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandGreenPrimary),
          onPressed: _saving ? null : _assign,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.white))
              : const Text('Assign'),
        ),
      ],
    );
  }
}
