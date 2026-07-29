import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/order_provider.dart';

class OrderTrackingScreen extends ConsumerWidget {
  const OrderTrackingScreen({super.key, required this.orderId, this.order});

  final String orderId;
  final OrderModel? order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveAsync = ref.watch(singleOrderProvider(orderId));
    final o = liveAsync.valueOrNull ?? order;
    final shop = ref.watch(currentShopProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.lightBackground,
        surfaceTintColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightOnSurface,
        elevation: 0,
        centerTitle: true,
        title: const Text('Order Tracking',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined),
            onPressed: () => _call(),
            tooltip: 'Support',
          ),
        ],
      ),
      body: o == null
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.brandGreenPrimary))
          : RefreshIndicator(
              color: AppColors.brandGreenPrimary,
              onRefresh: () async =>
                  ref.invalidate(singleOrderProvider(orderId)),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _OrderSummaryCard(order: o),
                  const SizedBox(height: AppSpacing.xl),
                  _Timeline(status: o.status, placedAt: o.placedAt),
                  const SizedBox(height: AppSpacing.xl),
                  _DeliveryDetails(order: o, shop: shop),
                  const SizedBox(height: AppSpacing.x3l),
                ],
              ),
            ),
    );
  }

  static Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: '0800000000');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

// ── Steps ─────────────────────────────────────────────────────────────────────

class _Step {
  const _Step(this.status, this.label, this.icon);
  final String status;
  final String label;
  final IconData icon;
}

const _steps = [
  _Step(OrderStatus.pending, 'Order received', Icons.receipt_long_rounded),
  _Step(OrderStatus.confirmed, 'Order confirmed', Icons.thumb_up_rounded),
  _Step(OrderStatus.preparing, 'Preparing your order', Icons.inventory_2_rounded),
  _Step(OrderStatus.outForDelivery, 'Out for delivery',
      Icons.local_shipping_rounded),
  _Step(OrderStatus.delivered, 'Delivered', Icons.home_rounded),
];

int _indexFor(String status) {
  switch (status) {
    case OrderStatus.pending:
      return 0;
    case OrderStatus.confirmed:
      return 1;
    case OrderStatus.preparing:
    case AppConstants.orderStatusPacked:
      return 2;
    case OrderStatus.outForDelivery:
    case AppConstants.orderStatusAssigned:
      return 3;
    case OrderStatus.delivered:
      return 4;
    default:
      return 0;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case OrderStatus.confirmed:
      return 'Confirmed';
    case OrderStatus.preparing:
    case AppConstants.orderStatusPacked:
      return 'Preparing';
    case OrderStatus.outForDelivery:
    case AppConstants.orderStatusAssigned:
      return 'Out for delivery';
    case OrderStatus.delivered:
      return 'Delivered';
    case AppConstants.orderStatusCancelled:
      return 'Cancelled';
    default:
      return 'Order received';
  }
}

String _fmt(DateTime d) {
  const months = [
    'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
  ];
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${months[d.month - 1]} ${d.year}, $h:$m';
}

// ── Order summary (dark green card) ────────────────────────────────────────────

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final ref = order.orderNumber.isNotEmpty
        ? order.orderNumber
        : order.localUuid.split('-').first.toUpperCase();
    final payment = order.paymentMethod == AppConstants.paymentEft
        ? 'EFT / Bank transfer'
        : 'Pay on delivery';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.brandGreenDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Order #$ref',
                    style: AppTypography.titleMedium.copyWith(
                        color: AppColors.white, fontWeight: FontWeight.w800)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.brandGold,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(_statusLabel(order.status),
                    style: AppTypography.labelSmall.copyWith(
                        color: AppColors.brandGreenDark,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _row('Order placed', _fmt(order.placedAt)),
          const SizedBox(height: AppSpacing.sm),
          _row('Total amount', CurrencyFormatter.format(order.totalCents)),
          const SizedBox(height: AppSpacing.sm),
          _row('Payment method', payment),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: AppTypography.bodySmall.copyWith(
                    color: AppColors.white.withValues(alpha: 0.7))),
          ),
          Expanded(
            child: Text(value,
                style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      );
}

// ── Timeline ──────────────────────────────────────────────────────────────────

class _Timeline extends StatelessWidget {
  const _Timeline({required this.status, required this.placedAt});
  final String status;
  final DateTime placedAt;

  @override
  Widget build(BuildContext context) {
    final current = _indexFor(status);
    return Column(
      children: List.generate(_steps.length, (i) {
        final step = _steps[i];
        final isDone = i < current;
        final isCurrent = i == current;
        final isLast = i == _steps.length - 1;
        final active = isDone || isCurrent;

        // Secondary line: real time for the first step, else status word.
        final secondary = i == 0
            ? _fmt(placedAt)
            : isDone
                ? 'Completed'
                : isCurrent
                    ? 'In progress'
                    : 'Pending';

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active
                          ? AppColors.brandGreenPrimary
                          : AppColors.lightSurfaceVariant,
                    ),
                    child: Icon(
                      isDone ? Icons.check_rounded : step.icon,
                      size: isDone ? 20 : 16,
                      color:
                          active ? AppColors.white : AppColors.lightOnSurfaceVariant,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isDone
                            ? AppColors.brandGreenPrimary
                            : AppColors.lightOutlineVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step.label,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                            color: active
                                ? AppColors.lightOnSurface
                                : AppColors.lightOnSurfaceVariant,
                          )),
                      const SizedBox(height: 2),
                      Text(secondary,
                          style: AppTypography.bodySmall.copyWith(
                              color: AppColors.lightOnSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ── Delivery details ───────────────────────────────────────────────────────────

class _DeliveryDetails extends StatelessWidget {
  const _DeliveryDetails({required this.order, this.shop});
  final OrderModel order;
  final ShopModel? shop;

  @override
  Widget build(BuildContext context) {
    final eta = order.scheduledDeliveryDate != null
        ? _fmt(order.scheduledDeliveryDate!)
        : 'We\'ll confirm your delivery window soon';
    final address = order.deliveryAddress.isNotEmpty
        ? order.deliveryAddress
        : [shop?.physicalAddress ?? '', shop?.city ?? '']
            .where((s) => s.isNotEmpty)
            .join(', ');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Delivery details',
              style:
                  AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.lg),
          Text('Expected delivery time',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.lightOnSurfaceVariant)),
          const SizedBox(height: 2),
          Text(eta,
              style: AppTypography.bodyLarge
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Delivery to',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.lightOnSurfaceVariant)),
                    const SizedBox(height: 2),
                    Text(shop?.shopName ?? 'Your shop',
                        style: AppTypography.bodyLarge
                            .copyWith(fontWeight: FontWeight.w700)),
                    if (address.isNotEmpty)
                      Text(address,
                          style: AppTypography.bodySmall.copyWith(
                              color: AppColors.lightOnSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              InkWell(
                onTap: OrderTrackingScreen._call,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.brandGreenPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.call_rounded,
                      color: AppColors.white, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
