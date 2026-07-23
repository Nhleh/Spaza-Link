import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:spazalink_core/core.dart';

import 'product_card.dart';

/// 2-column product grid with shimmer loading state.
class ProductGrid extends StatelessWidget {
  const ProductGrid({
    super.key,
    required this.products,
    this.isLoading = false,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
  });

  final List<ProductModel> products;
  final bool isLoading;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _ShimmerGrid(padding: padding);

    if (products.isEmpty) {
      return Padding(
        padding: padding ?? EdgeInsets.zero,
        child: const EmptyStateWidget(
          type: EmptyStateType.noProducts,
          compact: true,
        ),
      );
    }

    return GridView.builder(
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.62,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) => ProductCard(product: products[i]),
    );
  }
}

class _ShimmerGrid extends StatelessWidget {
  const _ShimmerGrid({this.padding});
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.62,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const _ShimmerCard(),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.lightSurfaceVariant,
      highlightColor: AppColors.lightOutlineVariant,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.lightSurfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.productCardRadius),
        ),
      ),
    );
  }
}
