import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';

import '../providers/order_provider.dart';
import '../widgets/order_status_badge.dart';

class OrderTrackingScreen extends ConsumerWidget {
  const OrderTrackingScreen({
    super.key,
    required this.orderId,
    this.order,
  });

  final String orderId;
  final OrderModel? order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveAsync = ref.watch(singleOrderProvider(orderId));
    final o = liveAsync.valueOrNull ?? order;

    if (o == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.brandGreenPrimary,
          foregroundColor: AppColors.white,
          title: const Text('Tracking'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.brandGreenPrimary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.brandGreenPrimary,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Track Delivery',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700),
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
            // ── Map placeholder ──────────────────────────────────────────────
            _MapPlaceholder(status: o.status),

            const SizedBox(height: AppSpacing.x3l),

            // ── Delivery status ──────────────────────────────────────────────
            _DeliveryStatusCard(order: o),

            const SizedBox(height: AppSpacing.x3l),

            // ── Delivery address ─────────────────────────────────────────────
            _InfoCard(
              icon: Icons.location_on_outlined,
              title: 'Delivering to',
              body: o.deliveryAddress,
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Order ref ────────────────────────────────────────────────────
            _InfoCard(
              icon: Icons.receipt_outlined,
              title: 'Order reference',
              body: o.orderNumber.isNotEmpty ? o.orderNumber : o.localUuid,
              bodyStyle: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),

            const SizedBox(height: AppSpacing.x5l),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final isDelivered = status == OrderStatus.delivered;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.brandGreenSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.lightOutlineVariant),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Grid lines to suggest a map
          CustomPaint(
            painter: _MapGridPainter(),
            child: const SizedBox.expand(),
          ),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isDelivered
                    ? Icons.check_circle_rounded
                    : Icons.local_shipping_rounded,
                size: 48,
                color: AppColors.brandGreenPrimary,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                isDelivered
                    ? 'Order delivered!'
                    : 'Live map coming soon',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.brandGreenPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!isDelivered)
                Text(
                  'Driver location tracking in Phase 9',
                  style: AppTypography.bodySmall.copyWith(
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

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.brandGreenLight.withValues(alpha: 0.15)
      ..strokeWidth = 1;

    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _DeliveryStatusCard extends StatelessWidget {
  const _DeliveryStatusCard({required this.order});
  final OrderModel order;

  static const _deliverySteps = [
    (OrderStatus.outForDelivery, 'Driver assigned', Icons.person_outlined),
    (OrderStatus.outForDelivery, 'On the way', Icons.local_shipping_outlined),
    (OrderStatus.delivered, 'Delivered', Icons.verified_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final isDelivered = order.status == OrderStatus.delivered;
    final activeIndex = isDelivered ? 2 : 1;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.lightOutlineVariant),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Status',
            style: AppTypography.titleSmall
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...List.generate(_deliverySteps.length, (i) {
            final step = _deliverySteps[i];
            final isDone = i < activeIndex;
            final isActive = i == activeIndex;
            final isLast = i == _deliverySteps.length - 1;
            final color = isDone || isActive
                ? AppColors.brandGreenPrimary
                : AppColors.lightOutline;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                                ? Icon(step.$3,
                                    size: 10, color: AppColors.white)
                                : null,
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 32,
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
                    step.$2,
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
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
    this.bodyStyle,
  });

  final IconData icon;
  final String title;
  final String body;
  final TextStyle? bodyStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.lightOutlineVariant),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.brandGreenPrimary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.lightOnSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: bodyStyle ??
                      AppTypography.bodyMedium.copyWith(
                        color: AppColors.lightOnSurface,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
