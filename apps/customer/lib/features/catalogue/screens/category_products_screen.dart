import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

import '../../cart/providers/cart_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../products/widgets/product_grid.dart';

class CategoryProductsScreen extends ConsumerWidget {
  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
    this.category,
  });

  final String categoryId;
  final CategoryModel? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(categoryProductsProvider(categoryId));
    final shopId = ref.watch(currentShopProvider).valueOrNull?.id ?? '';
    final cartCount = ref.watch(cartItemCountProvider(shopId));

    final title = category?.name ?? 'Products';

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.brandGreenPrimary,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => context.go(RouteConstants.cart),
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppColors.brandGold,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cartCount > 99 ? '99+' : '$cartCount',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => ProductGrid(
          products: const [],
          isLoading: true,
          padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
        ),
        error: (e, _) => EmptyStateWidget(
          type: EmptyStateType.error,
          message: 'Could not load products.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(categoryProductsProvider(categoryId)),
        ),
        data: (products) => RefreshIndicator(
          color: AppColors.brandGreenPrimary,
          onRefresh: () async =>
              ref.invalidate(categoryProductsProvider(categoryId)),
          child: ProductGrid(
            products: products,
            padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
          ),
        ),
      ),
    );
  }
}
