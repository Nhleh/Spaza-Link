import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../widgets/order_status_badge.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopId = ref.watch(currentShopProvider).valueOrNull?.id ?? '';
    final ordersAsync = ref.watch(shopOrdersProvider(shopId));

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.brandGreenPrimary,
        foregroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'My Orders',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: ordersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandGreenPrimary),
        ),
        error: (e, _) => EmptyStateWidget(
          type: EmptyStateType.error,
          message: 'Could not load orders.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(shopOrdersProvider(shopId)),
        ),
        data: (orders) {
          if (orders.isEmpty) return const _EmptyOrders();

          // Newest first
          final sorted = [...orders]
            ..sort((a, b) => b.placedAt.compareTo(a.placedAt));

          return RefreshIndicator(
            color: AppColors.brandGreenPrimary,
            onRefresh: () async => ref.invalidate(shopOrdersProvider(shopId)),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.screenPaddingH,
              ),
              itemCount: sorted.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) => _OrderCard(order: sorted[i]),
            ),
          );
        },
      ),
    );
  }
}

// ── Order card ────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final displayRef = order.orderNumber.isNotEmpty
        ? order.orderNumber
        : 'Local — syncing…';

    return GestureDetector(
      onTap: () {
        final id = order.id.isNotEmpty ? order.id : order.localUuid;
        context.push('/orders/$id', extra: order);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.lightOutlineVariant),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: ref + status
            Row(
              children: [
                Expanded(
                  child: Text(
                    displayRef,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                OrderStatusBadge(status: order.status, compact: true),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // Date
            Text(
              _formatDate(order.placedAt),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.lightOnSurfaceVariant,
              ),
            ),

            const SizedBox(height: AppSpacing.md),
            const Divider(color: AppColors.lightOutlineVariant, height: 1),
            const SizedBox(height: AppSpacing.md),

            // Items preview
            Text(
              order.items.take(2).map((i) => i.productName).join(', ') +
                  (order.items.length > 2
                      ? ' +${order.items.length - 2} more'
                      : ''),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.lightOnSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: AppSpacing.sm),

            // Bottom: item count + total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.items.length} item${order.items.length == 1 ? '' : 's'}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.lightOnSurfaceVariant,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(order.totalCents),
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightOnSurface,
                  ),
                ),
              ],
            ),

            // Offline sync notice
            if (order.syncStatus == SyncStatus.local) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.sync_outlined,
                      size: 12, color: AppColors.syncPending),
                  const SizedBox(width: 4),
                  Text(
                    'Pending sync',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.syncPending,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  $h:$m';
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x5l),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.brandGreenSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 44,
                color: AppColors.brandGreenPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.x3l),
            Text(
              'No orders yet',
              style: AppTypography.headlineSmall
                  .copyWith(color: AppColors.lightOnSurface),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your order history will appear here once you place your first order.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.lightOnSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.x3l),
            SizedBox(
              height: AppSpacing.buttonHeight,
              child: ElevatedButton(
                onPressed: () => context.go(RouteConstants.catalogue),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandGreenPrimary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.x3l),
                ),
                child: const Text(
                  'Start Shopping',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
