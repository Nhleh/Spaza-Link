import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopId = ref.watch(currentShopProvider).valueOrNull?.id ?? '';
    final itemsAsync = ref.watch(cartItemsProvider(shopId));

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.brandGreenPrimary,
        foregroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'My Cart',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          itemsAsync.valueOrNull?.isNotEmpty == true
              ? TextButton(
                  onPressed: () => _confirmClearCart(context, ref, shopId),
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandGreenPrimary),
        ),
        error: (e, _) => EmptyStateWidget(
          type: EmptyStateType.error,
          message: 'Could not load cart.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(cartItemsProvider(shopId)),
        ),
        data: (items) {
          if (items.isEmpty) return const _EmptyCart();
          return _CartBody(shopId: shopId, items: items);
        },
      ),
    );
  }

  Future<void> _confirmClearCart(
    BuildContext context,
    WidgetRef ref,
    String shopId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear cart?'),
        content: const Text('All items will be removed from your cart.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Clear',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      ref.read(cartNotifierProvider.notifier).clearCart(shopId);
    }
  }
}

// ── Body: item list + summary ─────────────────────────────────────────────────

class _CartBody extends ConsumerWidget {
  const _CartBody({required this.shopId, required this.items});

  final String shopId;
  final List<CartItemModel> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtotal = ref.watch(cartSubtotalProvider(shopId));
    final fee = ref.watch(cartDeliveryFeeProvider(shopId));
    final total = ref.watch(cartTotalProvider(shopId));
    final meetsMin = ref.watch(meetsMinOrderProvider(shopId));

    return Column(
      children: [
        // ── Minimum order warning ────────────────────────────────────────────
        if (!meetsMin) _MinOrderBanner(subtotal: subtotal),

        // ── Item list ───────────────────────────────────────────────────────
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: AppSpacing.screenPaddingH,
            ),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, i) =>
                _CartItemTile(item: items[i], shopId: shopId),
          ),
        ),

        // ── Summary + checkout button ────────────────────────────────────────
        _CartSummary(
          shopId: shopId,
          subtotal: subtotal,
          fee: fee,
          total: total,
          meetsMin: meetsMin,
        ),
      ],
    );
  }
}

// ── Item tile ─────────────────────────────────────────────────────────────────

class _CartItemTile extends ConsumerWidget {
  const _CartItemTile({required this.item, required this.shopId});

  final CartItemModel item;
  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.lightOutlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: item.imageUrl?.isNotEmpty == true
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 72,
                        height: 72,
                        color: AppColors.brandGreenSurfaceLight,
                      ),
                      errorWidget: (_, __, ___) => _ImagePlaceholder(),
                    )
                  : _ImagePlaceholder(),
            ),

            const SizedBox(width: AppSpacing.md),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.lightOnSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (item.packSize.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.packSize,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.lightOnSurfaceVariant,
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.sm),

                  // Price + qty row
                  Row(
                    children: [
                      // Line total
                      Text(
                        CurrencyFormatter.format(item.lineTotalCents),
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.brandGreenPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      if (item.salePriceCents != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          CurrencyFormatter.format(
                              item.priceCents * item.quantity),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.lightOnSurfaceVariant,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],

                      const Spacer(),

                      // Qty controls
                      _QtyRow(item: item, shopId: shopId),
                    ],
                  ),
                ],
              ),
            ),

            // Remove
            GestureDetector(
              onTap: () => ref
                  .read(cartNotifierProvider.notifier)
                  .removeItem(productId: item.productId, shopId: shopId),
              child: const Padding(
                padding: EdgeInsets.only(left: AppSpacing.sm),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.lightOnSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      color: AppColors.brandGreenSurfaceLight,
      child: const Icon(
        Icons.inventory_2_outlined,
        color: AppColors.brandGreenPrimary,
        size: 28,
      ),
    );
  }
}

class _QtyRow extends ConsumerWidget {
  const _QtyRow({required this.item, required this.shopId});

  final CartItemModel item;
  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartNotifierProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lightOutline),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyBtn(
            icon: item.quantity == 1
                ? Icons.delete_outline_rounded
                : Icons.remove_rounded,
            color: item.quantity == 1
                ? AppColors.error
                : AppColors.brandGreenPrimary,
            onTap: () => notifier.updateQuantity(
              productId: item.productId,
              shopId: shopId,
              quantity: item.quantity - 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              '${item.quantity}',
              style: AppTypography.bodyMedium
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          _QtyBtn(
            icon: Icons.add_rounded,
            color: AppColors.brandGreenPrimary,
            onTap: () => notifier.updateQuantity(
              productId: item.productId,
              shopId: shopId,
              quantity: item.quantity + 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _CartSummary extends StatelessWidget {
  const _CartSummary({
    required this.shopId,
    required this.subtotal,
    required this.fee,
    required this.total,
    required this.meetsMin,
  });

  final String shopId;
  final int subtotal;
  final int fee;
  final int total;
  final bool meetsMin;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        border: const Border(
          top: BorderSide(color: AppColors.lightOutlineVariant),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingH,
        AppSpacing.lg,
        AppSpacing.screenPaddingH,
        0,
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Free delivery progress
            if (fee > 0) ...[
              _FreeDeliveryProgress(subtotal: subtotal),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Line items
            _SummaryRow(
              label: 'Subtotal',
              value: CurrencyFormatter.format(subtotal),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SummaryRow(
              label: 'Delivery',
              value: CurrencyFormatter.formatDeliveryFee(fee),
              valueColor: fee == 0 ? AppColors.brandGreenPrimary : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(color: AppColors.lightOutlineVariant),
            const SizedBox(height: AppSpacing.sm),
            _SummaryRow(
              label: 'Total',
              value: CurrencyFormatter.format(total),
              bold: true,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Checkout button
            SizedBox(
              height: AppSpacing.buttonHeight,
              child: ElevatedButton(
                onPressed: meetsMin
                    ? () => context.push(RouteConstants.checkout)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandGreenPrimary,
                  disabledBackgroundColor:
                      AppColors.lightOnSurfaceVariant.withValues(alpha: 0.2),
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  meetsMin
                      ? 'Proceed to Checkout — ${CurrencyFormatter.format(total)}'
                      : 'Minimum order not reached',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
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
        ? AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)
        : AppTypography.bodyMedium;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: style.copyWith(color: AppColors.lightOnSurfaceVariant)),
        Text(value,
            style: style.copyWith(
              color: valueColor ?? AppColors.lightOnSurface,
            )),
      ],
    );
  }
}

class _FreeDeliveryProgress extends StatelessWidget {
  const _FreeDeliveryProgress({required this.subtotal});
  final int subtotal;

  @override
  Widget build(BuildContext context) {
    final threshold = AppConstants.freeDeliveryThresholdCents;
    final progress = (subtotal / threshold).clamp(0.0, 1.0);
    final remaining = threshold - subtotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          remaining > 0
              ? 'Add ${CurrencyFormatter.format(remaining)} more for FREE delivery'
              : 'You have FREE delivery!',
          style: AppTypography.bodySmall.copyWith(
            color: remaining > 0
                ? AppColors.lightOnSurfaceVariant
                : AppColors.brandGreenPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.lightSurfaceVariant,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.brandGreenPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _MinOrderBanner extends StatelessWidget {
  const _MinOrderBanner({required this.subtotal});
  final int subtotal;

  @override
  Widget build(BuildContext context) {
    final remaining = AppConstants.minOrderCents - subtotal;
    return Container(
      width: double.infinity,
      color: AppColors.brandGold.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingH,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.brandGold,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Minimum order is ${CurrencyFormatter.format(AppConstants.minOrderCents)}. '
              'Add ${CurrencyFormatter.format(remaining)} more to continue.',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.lightOnSurface),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

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
              decoration: BoxDecoration(
                color: AppColors.brandGreenSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 44,
                color: AppColors.brandGreenPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.x3l),
            Text(
              'Your cart is empty',
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.lightOnSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Browse the catalogue and add products to get started.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.lightOnSurfaceVariant,
              ),
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
