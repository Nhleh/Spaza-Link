import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

import '../../auth/providers/auth_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../pools/widgets/create_pool_sheet.dart';
import '../../products/providers/product_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.product,
  });

  final String productId;
  final ProductModel? product;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState
    extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  int _imageIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use passed product immediately; also subscribe for live updates.
    final liveAsync = ref.watch(singleProductProvider(widget.productId));
    final product = liveAsync.valueOrNull ?? widget.product;

    final shopId = ref.watch(currentShopProvider).valueOrNull?.id ?? '';
    final items = ref.watch(cartItemsProvider(shopId)).valueOrNull ?? [];
    final cartItem =
        items.where((i) => i.productId == widget.productId).firstOrNull;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.brandGreenPrimary,
          foregroundColor: AppColors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final effectiveQty = cartItem?.quantity ?? _quantity;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          // ── Image header ─────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.brandGreenPrimary,
            foregroundColor: AppColors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: _ProductImageGallery(
                product: product,
                controller: _pageController,
                currentIndex: _imageIndex,
                onPageChanged: (i) => setState(() => _imageIndex = i),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image dots
                  if (product.imageUrls.length > 1) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        product.imageUrls.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _imageIndex == i ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _imageIndex == i
                                ? AppColors.brandGreenPrimary
                                : AppColors.lightOutline,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Sale badge
                  if (product.isOnSale) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandGold,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        'SPECIAL OFFER',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],

                  // Name
                  Text(
                    product.name,
                    style: AppTypography.headlineSmall.copyWith(
                      color: AppColors.lightOnSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Pack size + SKU
                  Row(
                    children: [
                      if (product.packSize.isNotEmpty) ...[
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 14,
                          color: AppColors.lightOnSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.packSize,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.lightOnSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                      ],
                      if (product.sku.isNotEmpty) ...[
                        const Icon(
                          Icons.qr_code_rounded,
                          size: 14,
                          color: AppColors.lightOnSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'SKU: ${product.sku}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.lightOnSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),
                  const Divider(color: AppColors.lightOutlineVariant),
                  const SizedBox(height: AppSpacing.xl),

                  // Price
                  _PriceSection(product: product),

                  const SizedBox(height: AppSpacing.xl),

                  // Start a buying pool
                  _StartPoolTile(product: product),

                  const SizedBox(height: AppSpacing.x3l),

                  // Description
                  if (product.description.isNotEmpty) ...[
                    Text(
                      'About this product',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      product.description,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.lightOnSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x3l),
                  ],

                  // Tags
                  if (product.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: product.tags
                          .map((t) => Chip(
                                label: Text(t),
                                labelStyle: AppTypography.labelSmall.copyWith(
                                  color: AppColors.brandGreenPrimary,
                                ),
                                backgroundColor: AppColors.brandGreenSurface,
                                side: const BorderSide(
                                    color: AppColors.brandGreenLight),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.x3l),
                  ],

                  // Spacer for bottom bar
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Sticky bottom: qty + add to cart ───────────────────────────────
      bottomNavigationBar: product.isAvailable
          ? _StickyCartBar(
              product: product,
              shopId: shopId,
              cartItem: cartItem,
              quantity: effectiveQty,
              onDecrement: () => setState(() {
                if (_quantity > 1) _quantity--;
              }),
              onIncrement: () => setState(() => _quantity++),
            )
          : const _OutOfStockBar(),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

/// CTA to start a buying pool for this product (needs >= 50 units).
class _StartPoolTile extends ConsumerWidget {
  const _StartPoolTile({required this.product});
  final ProductModel product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      onTap: () => showCreatePoolSheet(context, ref, product),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.brandGreenSurfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.brandGreenLight),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.brandGreenPrimary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: const Icon(Icons.groups_rounded,
                  color: AppColors.white, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Start a buying pool',
                      style: AppTypography.titleSmall
                          .copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text('Add 50+ units and let other shops join — up to 15% off',
                      style: AppTypography.bodySmall.copyWith(
                          color: AppColors.lightOnSurfaceVariant)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.brandGreenPrimary),
          ],
        ),
      ),
    );
  }
}

class _ProductImageGallery extends StatelessWidget {
  const _ProductImageGallery({
    required this.product,
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
  });

  final ProductModel product;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (product.imageUrls.isEmpty) {
      return Container(
        color: AppColors.brandGreenSurfaceLight,
        alignment: Alignment.center,
        child: const Icon(
          Icons.inventory_2_outlined,
          color: AppColors.brandGreenPrimary,
          size: 80,
        ),
      );
    }

    return PageView.builder(
      controller: controller,
      onPageChanged: onPageChanged,
      itemCount: product.imageUrls.length,
      itemBuilder: (_, i) => ColoredBox(
        // White backdrop so the full product image shows (contain) without
        // being cropped, and letterboxing looks intentional.
        color: AppColors.white,
        child: CachedNetworkImage(
          imageUrl: product.imageUrls[i],
          fit: BoxFit.contain,
          placeholder: (_, __) => const Center(
            child:
                CircularProgressIndicator(color: AppColors.brandGreenPrimary),
          ),
          errorWidget: (_, __, ___) => Container(
            color: AppColors.brandGreenSurfaceLight,
            child: const Icon(
              Icons.broken_image_outlined,
              color: AppColors.lightOnSurfaceVariant,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}

class _PriceSection extends StatelessWidget {
  const _PriceSection({required this.product});
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    if (product.isOnSale) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            CurrencyFormatter.format(product.salePriceCents!),
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.brandGreenPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              CurrencyFormatter.format(product.priceCents),
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.lightOnSurfaceVariant,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: AppColors.brandGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                CurrencyFormatter.formatSavings(
                  product.priceCents - product.salePriceCents!,
                ),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.brandGold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Text(
      CurrencyFormatter.format(product.priceCents),
      style: AppTypography.headlineMedium.copyWith(
        color: AppColors.lightOnSurface,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _StickyCartBar extends ConsumerWidget {
  const _StickyCartBar({
    required this.product,
    required this.shopId,
    required this.cartItem,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final ProductModel product;
  final String shopId;
  final CartItemModel? cartItem;
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inCart = cartItem != null;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPaddingH,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.lightSurface,
          border: const Border(
            top: BorderSide(color: AppColors.lightOutlineVariant),
          ),
        ),
        child: Row(
          children: [
            // Qty controls
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.lightOutline),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  _QtyBtn(
                    icon: Icons.remove_rounded,
                    onTap: inCart
                        ? () => ref
                            .read(cartNotifierProvider.notifier)
                            .updateQuantity(
                              productId: product.id,
                              shopId: shopId,
                              quantity: cartItem!.quantity - 1,
                            )
                        : onDecrement,
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '$quantity',
                      textAlign: TextAlign.center,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _QtyBtn(
                    icon: Icons.add_rounded,
                    onTap: inCart
                        ? () => ref
                            .read(cartNotifierProvider.notifier)
                            .updateQuantity(
                              productId: product.id,
                              shopId: shopId,
                              quantity: cartItem!.quantity + 1,
                            )
                        : onIncrement,
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Add to cart / Go to cart
            Expanded(
              child: SizedBox(
                height: AppSpacing.buttonHeight,
                child: ElevatedButton(
                  onPressed: inCart
                      ? () => context.push(RouteConstants.cart)
                      : () => _addToCart(ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreenPrimary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.buttonRadius),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    inCart
                        ? 'View Cart (${cartItem!.quantity})'
                        : 'Add to Cart — ${CurrencyFormatter.format(product.effectivePriceCents * quantity)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
            quantity: quantity,
            addedAt: DateTime.now(),
          ),
        );
  }
}

class _OutOfStockBar extends StatelessWidget {
  const _OutOfStockBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: AppSpacing.buttonHeight + AppSpacing.xxl,
        alignment: Alignment.center,
        color: AppColors.lightSurface,
        child: Text(
          'This product is currently out of stock',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.lightOnSurfaceVariant,
          ),
        ),
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
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Icon(icon, size: 18, color: AppColors.brandGreenPrimary),
      ),
    );
  }
}
