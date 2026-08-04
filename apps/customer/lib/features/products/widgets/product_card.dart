import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:spazalink_core/core.dart';

import '../../cart/providers/cart_provider.dart';
import '../../auth/providers/auth_provider.dart';

class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopId = ref.watch(currentShopProvider).valueOrNull?.id ?? '';
    final items = ref.watch(cartItemsProvider(shopId)).valueOrNull ?? [];
    final cartItem = items.where((i) => i.productId == product.id).firstOrNull;
    final inCart = cartItem != null;

    return GestureDetector(
      onTap: () => context.push(
        RouteConstants.productDetail.replaceFirst(':productId', product.id),
        extra: product,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppSpacing.productCardRadius),
          border: Border.all(color: AppColors.lightOutlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ──────────────────────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.productCardRadius),
              ),
              child: Stack(
                children: [
                  _ProductImage(imageUrl: product.primaryImageUrl),
                  if (product.isOnSale) _SaleTag(product: product),
                  if (!product.isAvailable)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black45,
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Text(
                            'Out of Stock',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Details ────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.xs,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fixed 2-line name area — keeps every card the same height.
                    SizedBox(
                      height: 32,
                      child: Text(
                        product.name,
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.lightOnSurface,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Fixed 1-line pack-size area (always reserved).
                    SizedBox(
                      height: 14,
                      child: Text(
                        product.packSize,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.lightOnSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    _PriceRow(product: product),
                    const SizedBox(height: AppSpacing.xs),
                    _CartButton(
                      product: product,
                      shopId: shopId,
                      cartItem: cartItem,
                      inCart: inCart,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ProductImage extends StatelessWidget {
  const _ProductImage({this.imageUrl});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        height: AppSpacing.productCardImageHeight,
        color: AppColors.brandGreenSurfaceLight,
        child: const Center(
          child: Icon(
            Icons.inventory_2_outlined,
            color: AppColors.brandGreenPrimary,
            size: 36,
          ),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      height: AppSpacing.productCardImageHeight,
      width: double.infinity,
      // Contain (on the card's white surface) shows the whole product, uncropped.
      fit: BoxFit.contain,
      placeholder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.lightSurfaceVariant,
        highlightColor: AppColors.lightOutlineVariant,
        child: Container(
          height: AppSpacing.productCardImageHeight,
          color: AppColors.lightSurfaceVariant,
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        height: AppSpacing.productCardImageHeight,
        color: AppColors.brandGreenSurfaceLight,
        child: const Icon(
          Icons.broken_image_outlined,
          color: AppColors.lightOnSurfaceVariant,
          size: 32,
        ),
      ),
    );
  }
}

class _SaleTag extends StatelessWidget {
  const _SaleTag({required this.product});
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    if (product.salePriceCents == null || product.priceCents == 0) {
      return const SizedBox.shrink();
    }
    final pct = (((product.priceCents - product.salePriceCents!) /
                product.priceCents) *
            100)
        .round();
    return Positioned(
      top: AppSpacing.xs,
      left: AppSpacing.xs,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: AppColors.brandGold,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Text(
          '-$pct%',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.product});
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final onSale = product.isOnSale;
    // Single line so every card is the same height; the -X% badge on the image
    // already signals the discount.
    return Text(
      CurrencyFormatter.format(
          onSale ? product.salePriceCents! : product.priceCents),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.titleSmall.copyWith(
        color:
            onSale ? AppColors.brandGreenPrimary : AppColors.lightOnSurface,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _CartButton extends ConsumerWidget {
  const _CartButton({
    required this.product,
    required this.shopId,
    required this.cartItem,
    required this.inCart,
  });

  final ProductModel product;
  final String shopId;
  final CartItemModel? cartItem;
  final bool inCart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!product.isAvailable) return const SizedBox.shrink();

    if (!inCart) {
      return SizedBox(
        width: double.infinity,
        height: 32,
        child: ElevatedButton(
          onPressed: () => _addToCart(ref),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandGreenPrimary,
            foregroundColor: AppColors.white,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, size: 16),
              SizedBox(width: 4),
              Text('Add', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    // Already in cart — show quantity controls.
    return Row(
      children: [
        _QtyBtn(
          icon: Icons.remove_rounded,
          onTap: () => ref.read(cartNotifierProvider.notifier).updateQuantity(
                productId: product.id,
                shopId: shopId,
                quantity: (cartItem!.quantity - 1),
              ),
        ),
        Expanded(
          child: Text(
            '${cartItem!.quantity}',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall
                .copyWith(fontWeight: FontWeight.w700, color: AppColors.brandGreenPrimary),
          ),
        ),
        _QtyBtn(
          icon: Icons.add_rounded,
          onTap: () => ref.read(cartNotifierProvider.notifier).updateQuantity(
                productId: product.id,
                shopId: shopId,
                quantity: cartItem!.quantity + 1,
              ),
        ),
      ],
    );
  }

  void _addToCart(WidgetRef ref) {
    ref.read(cartNotifierProvider.notifier).addItem(
          CartItemModel(
            productId: product.id,
            shopId: shopId,
            productName: product.name,
            imageUrl: product.primaryImageUrl,
            priceCents: product.priceCents,
            salePriceCents: product.salePriceCents,
            packSize: product.packSize,
            quantity: 1,
            addedAt: DateTime.now(),
          ),
        );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.brandGreenSurface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Icon(icon, size: 16, color: AppColors.brandGreenPrimary),
      ),
    );
  }
}
