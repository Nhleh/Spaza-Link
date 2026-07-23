import 'package:flutter/material.dart';
import 'package:spazalink_core/core.dart';

/// Maps OrderStatus strings → display label, color, icon.
abstract final class OrderStatusMeta {
  static String label(String status) => switch (status) {
        OrderStatus.pending => 'Pending',
        OrderStatus.confirmed => 'Confirmed',
        OrderStatus.preparing => 'Preparing',
        OrderStatus.outForDelivery => 'On the Way',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Cancelled',
        _ => status,
      };

  static Color color(String status) => switch (status) {
        OrderStatus.pending => AppColors.statusPending,
        OrderStatus.confirmed => AppColors.statusConfirmed,
        OrderStatus.preparing => AppColors.statusPacked,
        OrderStatus.outForDelivery => AppColors.statusOutForDelivery,
        OrderStatus.delivered => AppColors.statusDelivered,
        OrderStatus.cancelled => AppColors.statusCancelled,
        _ => AppColors.statusPending,
      };

  static IconData icon(String status) => switch (status) {
        OrderStatus.pending => Icons.hourglass_empty_rounded,
        OrderStatus.confirmed => Icons.check_circle_outline_rounded,
        OrderStatus.preparing => Icons.inventory_2_outlined,
        OrderStatus.outForDelivery => Icons.local_shipping_outlined,
        OrderStatus.delivered => Icons.verified_rounded,
        OrderStatus.cancelled => Icons.cancel_outlined,
        _ => Icons.hourglass_empty_rounded,
      };

  static bool isFinal(String status) =>
      status == OrderStatus.delivered || status == OrderStatus.cancelled;

  static bool canCancel(String status) =>
      status == OrderStatus.pending || status == OrderStatus.confirmed;
}

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status, this.compact = false});

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = OrderStatusMeta.color(status);
    final label = OrderStatusMeta.label(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? 2 : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(OrderStatusMeta.icon(status), size: compact ? 10 : 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: (compact ? AppTypography.labelSmall : AppTypography.labelMedium)
                .copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
