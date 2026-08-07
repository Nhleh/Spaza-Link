import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

import '../providers/order_provider.dart';
import '../widgets/order_status_badge.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({
    super.key,
    required this.orderId,
    this.order,
  });

  final String orderId;
  final OrderModel? order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use passed order immediately; subscribe for live updates (e.g. status change).
    final liveAsync = ref.watch(singleOrderProvider(orderId));
    final o = liveAsync.valueOrNull ?? order;

    if (o == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.brandGreenPrimary,
          foregroundColor: AppColors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.brandGreenPrimary),
        ),
      );
    }

    final displayRef = o.orderNumber.isNotEmpty ? o.orderNumber : 'Syncing…';
    final canTrack = o.status == OrderStatus.outForDelivery ||
        o.status == OrderStatus.delivered;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.brandGreenPrimary,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          displayRef,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
            fontSize: 16,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: OrderStatusBadge(status: o.status),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.brandGreenPrimary,
        onRefresh: () async => ref.invalidate(singleOrderProvider(orderId)),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
          children: [
            // ── Status timeline ────────────────────────────────────────────
            _StatusTimeline(status: o.status),

            const SizedBox(height: AppSpacing.x3l),

            // ── Track delivery button ──────────────────────────────────────
            if (canTrack) ...[
              SizedBox(
                height: AppSpacing.buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: () => context.push(
                    '/orders/$orderId/tracking',
                    extra: o,
                  ),
                  icon: const Icon(Icons.local_shipping_outlined, size: 18),
                  label: const Text(
                    'Track Delivery',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreenPrimary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.buttonRadius),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.x3l),
            ],

            // ── Items ──────────────────────────────────────────────────────
            _Section(
              title: 'Items (${o.items.length})',
              child: Column(
                children: o.items
                    .map((item) => _OrderItemRow(item: item))
                    .toList(),
              ),
            ),

            const SizedBox(height: AppSpacing.x3l),

            // ── Price breakdown ────────────────────────────────────────────
            _Section(
              title: 'Price Breakdown',
              child: Column(
                children: [
                  _PriceRow(
                    label: 'Subtotal',
                    value: CurrencyFormatter.format(o.subtotalCents),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _PriceRow(
                    label: 'Delivery',
                    value: CurrencyFormatter.formatDeliveryFee(
                        o.deliveryFeeCents),
                    valueColor: o.deliveryFeeCents == 0
                        ? AppColors.brandGreenPrimary
                        : null,
                  ),
                  if (o.discountAmountCents > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _PriceRow(
                      label: 'Discount',
                      value:
                          '−${CurrencyFormatter.format(o.discountAmountCents)}',
                      valueColor: AppColors.brandGreenPrimary,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(color: AppColors.lightOutlineVariant),
                  const SizedBox(height: AppSpacing.sm),
                  _PriceRow(
                    label: 'Total',
                    value: CurrencyFormatter.format(o.totalCents),
                    bold: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.x3l),

            // ── Delivery details ───────────────────────────────────────────
            _Section(
              title: 'Delivery Details',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Address',
                    value: o.deliveryAddress,
                  ),
                  if (o.notes?.isNotEmpty == true) ...[
                    const SizedBox(height: AppSpacing.md),
                    _DetailRow(
                      icon: Icons.notes_rounded,
                      label: 'Notes',
                      value: o.notes!,
                    ),
                  ],
                  if (o.scheduledDeliveryDate != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Scheduled for',
                      value: _formatDate(o.scheduledDeliveryDate!),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.x3l),

            // ── Payment ────────────────────────────────────────────────────
            _Section(
              title: 'Payment',
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.payments_outlined,
                    label: 'Method',
                    value: _paymentLabel(o.paymentMethod),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _DetailRow(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Status',
                    // A delivered order is paid (cash collected on delivery).
                    value: _paymentStatusLabel(
                      o.status == OrderStatus.delivered
                          ? PaymentStatus.paid
                          : o.paymentStatus,
                    ),
                    valueColor: (o.status == OrderStatus.delivered ||
                            o.paymentStatus == PaymentStatus.paid)
                        ? AppColors.brandGreenPrimary
                        : null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.x3l),

            // ── Order meta ─────────────────────────────────────────────────
            _Section(
              title: 'Order Info',
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Placed',
                    value: _formatDateTime(o.placedAt),
                  ),
                  if (o.syncStatus == SyncStatus.local) ...[
                    const SizedBox(height: AppSpacing.md),
                    _DetailRow(
                      icon: Icons.wifi_off_rounded,
                      label: 'Sync',
                      value: 'Saved offline — will sync on reconnect',
                      valueColor: AppColors.syncPending,
                    ),
                  ],
                ],
              ),
            ),

            // Cancel button (only if order is cancellable)
            if (OrderStatusMeta.canCancel(o.status)) ...[
              const SizedBox(height: AppSpacing.x3l),
              OutlinedButton(
                onPressed: () => _confirmCancel(context, ref, o),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                  minimumSize:
                      const Size(double.infinity, AppSpacing.buttonHeight),
                ),
                child: const Text(
                  'Cancel Order',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.x5l),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    WidgetRef ref,
    OrderModel o,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel order?'),
        content: const Text(
            'This action cannot be undone. The order will be cancelled.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Order'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Cancel Order',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      // Order cancellation handled by admin app / cloud function.
      // Here we just show a message (full implementation in admin phase).
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cancellation request sent.'),
          backgroundColor: AppColors.brandGreenPrimary,
        ),
      );
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatDateTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${_formatDate(dt)}  $h:$m';
  }

  String _paymentLabel(String method) => switch (method) {
        PaymentMethod.cod => 'Cash on Delivery',
        PaymentMethod.payfast => 'PayFast',
        PaymentMethod.ozow => 'Ozow EFT',
        PaymentMethod.yoco => 'Yoco Card',
        _ => method,
      };

  String _paymentStatusLabel(String ps) => switch (ps) {
        PaymentStatus.pending => 'Pending',
        PaymentStatus.paid => 'Paid',
        PaymentStatus.failed => 'Failed',
        PaymentStatus.refunded => 'Refunded',
        _ => ps,
      };
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.titleSmall
              .copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.lightSurface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.lightOutlineVariant),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: child,
        ),
      ],
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.status});
  final String status;

  static const _steps = [
    (OrderStatus.pending, 'Order Received'),
    (OrderStatus.confirmed, 'Confirmed'),
    (OrderStatus.preparing, 'Preparing'),
    (OrderStatus.outForDelivery, 'Out for Delivery'),
    (OrderStatus.delivered, 'Delivered'),
  ];

  int get _currentIndex {
    for (var i = 0; i < _steps.length; i++) {
      if (_steps[i].$1 == status) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (status == OrderStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_outlined,
                color: AppColors.error, size: 20),
            const SizedBox(width: AppSpacing.md),
            Text(
              'This order was cancelled.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    final current = _currentIndex;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.lightOutlineVariant),
      ),
      child: Column(
        children: List.generate(_steps.length, (i) {
          final isDone = i < current;
          final isActive = i == current;
          final isLast = i == _steps.length - 1;
          final color = isDone || isActive
              ? AppColors.brandGreenPrimary
              : AppColors.lightOutline;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dot + line column
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone || isActive
                            ? AppColors.brandGreenPrimary
                            : AppColors.lightSurfaceVariant,
                        border: Border.all(color: color, width: 2),
                      ),
                      child: isDone
                          ? const Icon(Icons.check_rounded,
                              size: 12, color: AppColors.white)
                          : isActive
                              ? const Icon(Icons.circle,
                                  size: 8, color: AppColors.white)
                              : null,
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 28,
                        color: isDone
                            ? AppColors.brandGreenPrimary
                            : AppColors.lightOutline,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Padding(
                padding: EdgeInsets.only(
                  top: 1,
                  bottom: isLast ? 0 : AppSpacing.lg,
                ),
                child: Text(
                  _steps[i].$2,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDone || isActive
                        ? AppColors.lightOnSurface
                        : AppColors.lightOnSurfaceVariant,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});
  final OrderItemModel item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: item.imageUrl?.isNotEmpty == true
                ? CachedNetworkImage(
                    imageUrl: item.imageUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _Thumb(),
                    errorWidget: (_, __, ___) => _Thumb(),
                  )
                : _Thumb(),
          ),
          const SizedBox(width: AppSpacing.md),
          // Name + pack size
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightOnSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.packSize.isNotEmpty)
                  Text(
                    item.packSize,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.lightOnSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Qty × price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(item.lineTotalCents),
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.lightOnSurface,
                ),
              ),
              Text(
                '×${item.quantity}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.lightOnSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 48,
        height: 48,
        color: AppColors.brandGreenSurfaceLight,
        child: const Icon(Icons.inventory_2_outlined,
            color: AppColors.brandGreenPrimary, size: 20),
      );
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
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
    final style = bold
        ? AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)
        : AppTypography.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: style.copyWith(color: AppColors.lightOnSurfaceVariant)),
        Text(value,
            style: style.copyWith(
                color: valueColor ?? AppColors.lightOnSurface)),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.lightOnSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.lightOnSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.bodySmall.copyWith(
                  color: valueColor ?? AppColors.lightOnSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
