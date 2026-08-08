import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

import '../../auth/providers/driver_auth_provider.dart';
import '../../location/driver_location_service.dart';
import '../models/delivery.dart';
import '../providers/delivery_provider.dart';

class DeliveriesListScreen extends ConsumerWidget {
  const DeliveriesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep GPS tracking in sync with whether there are active jobs.
    ref.watch(locationTrackingProvider);

    final async = ref.watch(myDeliveriesProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.brandGreenPrimary,
        foregroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('My Deliveries',
            style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(myDeliveriesProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: () async {
              await driverSignOut(ref);
            },
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.brandGreenPrimary)),
        error: (e, _) => Center(
          child: EmptyStateWidget(
            type: EmptyStateType.error,
            message: 'Could not load your deliveries.',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(myDeliveriesProvider),
          ),
        ),
        data: (deliveries) {
          if (deliveries.isEmpty) {
            return RefreshIndicator(
              color: AppColors.brandGreenPrimary,
              onRefresh: () async => ref.invalidate(myDeliveriesProvider),
              child: ListView(
                children: const [
                  SizedBox(height: 140),
                  Icon(Icons.local_shipping_outlined,
                      size: 64, color: AppColors.lightOnSurfaceVariant),
                  SizedBox(height: 16),
                  Center(
                    child: Text('No deliveries assigned yet.',
                        style: TextStyle(color: AppColors.lightOnSurfaceVariant)),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.brandGreenPrimary,
            onRefresh: () async => ref.invalidate(myDeliveriesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: deliveries.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) => _DeliveryCard(delivery: deliveries[i]),
            ),
          );
        },
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.delivery});
  final Delivery delivery;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lightSurface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: () => context.push(
          RouteConstants.driverDeliveryDetail
              .replaceFirst(':deliveryId', delivery.orderId),
          extra: delivery,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.lightOutlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('#${delivery.ref}',
                      style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.lightOnSurface)),
                  const Spacer(),
                  _StatusChip(delivery: delivery),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    delivery.isAssigned
                        ? Icons.store_rounded
                        : Icons.location_on_rounded,
                    size: 16,
                    color: AppColors.brandGreenPrimary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${delivery.currentTargetLabel}: '
                      '${delivery.currentTargetAddress.isEmpty ? "—" : delivery.currentTargetAddress}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.lightOnSurface),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${delivery.items.length} item(s)',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.lightOnSurfaceVariant)),
                  Text(CurrencyFormatter.format(delivery.totalCents),
                      style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.lightOnSurface)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.delivery});
  final Delivery delivery;

  @override
  Widget build(BuildContext context) {
    final label = delivery.isAssigned ? 'To collect' : 'Delivering';
    final color =
        delivery.isAssigned ? AppColors.brandGold : AppColors.brandGreenPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(label,
          style: AppTypography.labelSmall
              .copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}
