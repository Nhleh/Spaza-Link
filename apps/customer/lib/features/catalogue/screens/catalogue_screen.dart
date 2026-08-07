import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:spazalink_core/core.dart';

import '../../ads/widgets/ad_banner.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../categories/providers/category_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../products/widgets/product_card.dart';

class CatalogueScreen extends ConsumerStatefulWidget {
  const CatalogueScreen({super.key});

  @override
  ConsumerState<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends ConsumerState<CatalogueScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _categoryId; // null == All

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopId = ref.watch(currentShopProvider).valueOrNull?.id ?? '';
    final cartCount = ref.watch(cartItemCountProvider(shopId));

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.brandGreenPrimary,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Shop',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Search bar (green header)
          Container(
            color: AppColors.brandGreenPrimary,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPaddingH,
              0,
              AppSpacing.screenPaddingH,
              AppSpacing.lg,
            ),
            child: _SearchBar(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              onClear: () => setState(() {
                _searchController.clear();
                _query = '';
              }),
            ),
          ),

          // Category filter chips
          _CategoryChips(
            selectedId: _categoryId,
            onSelect: _selectCategory,
          ),

          // Sliding advertisement banner (hidden when there are no active ads).
          const AdBanner(),

          // Product list
          Expanded(
            child: _ProductList(
              query: _query.trim(),
              categoryId: _categoryId,
              shopId: shopId,
            ),
          ),
        ],
      ),
      // Bottom View Cart bar
      bottomNavigationBar:
          cartCount > 0 ? _ViewCartBar(shopId: shopId) : null,
    );
  }

  void _selectCategory(String? id) => setState(() => _categoryId = id);
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search products…',
          hintStyle: const TextStyle(
            color: AppColors.lightOnSurfaceVariant,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.lightOnSurfaceVariant,
            size: 20,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: AppColors.lightOnSurfaceVariant,
                  onPressed: onClear,
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

// ── Category chips ────────────────────────────────────────────────────────────

class _CategoryChips extends ConsumerWidget {
  const _CategoryChips({required this.selectedId, required this.onSelect});

  final String? selectedId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.maybeWhen(
      data: (cats) {
        if (cats.isEmpty) return const SizedBox.shrink();
        return Container(
          color: AppColors.lightSurface,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPaddingH,
              ),
              itemCount: cats.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return _Chip(
                    label: 'All',
                    selected: selectedId == null,
                    onTap: () => onSelect(null),
                  );
                }
                final c = cats[i - 1];
                return _Chip(
                  label: c.name,
                  selected: selectedId == c.id,
                  onTap: () => onSelect(c.id),
                );
              },
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.brandGreenPrimary
              : AppColors.lightSurfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: selected
                ? AppColors.brandGreenPrimary
                : AppColors.lightOutlineVariant,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: selected ? AppColors.white : AppColors.lightOnSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Product list ──────────────────────────────────────────────────────────────

class _ProductList extends ConsumerWidget {
  const _ProductList({
    required this.query,
    required this.categoryId,
    required this.shopId,
  });

  final String query;
  final String? categoryId;
  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Search takes precedence over the category filter.
    final AsyncValue<List<ProductModel>> productsAsync = query.isNotEmpty
        ? ref.watch(productSearchProvider(query))
        : ref.watch(categoryProductsProvider(categoryId));

    return productsAsync.when(
      loading: () => const _ProductListShimmer(),
      error: (e, _) => EmptyStateWidget(
        type: EmptyStateType.error,
        message: 'Could not load products.',
        actionLabel: 'Retry',
        onAction: () {
          if (query.isNotEmpty) {
            ref.invalidate(productSearchProvider(query));
          } else {
            ref.invalidate(categoryProductsProvider(categoryId));
          }
        },
      ),
      data: (products) {
        if (products.isEmpty) {
          return EmptyStateWidget(
            type: query.isNotEmpty
                ? EmptyStateType.searchEmpty
                : EmptyStateType.noProducts,
            compact: true,
            message: query.isNotEmpty
                ? 'No products match "$query".'
                : 'No products in this category yet.',
          );
        }
        // Uses the same ProductCard + GridView that Top Deals renders reliably
        // (bounded cell height via mainAxisExtent).
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPaddingH,
            AppSpacing.md,
            AppSpacing.screenPaddingH,
            AppSpacing.x4l,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            mainAxisExtent: 258,
          ),
          itemCount: products.length,
          itemBuilder: (_, i) => ProductCard(product: products[i]),
        );
      },
    );
  }
}

// ── View cart bar ─────────────────────────────────────────────────────────────

class _ViewCartBar extends ConsumerWidget {
  const _ViewCartBar({required this.shopId});
  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartItemCountProvider(shopId));
    final total = ref.watch(cartTotalProvider(shopId));

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingH,
        0,
        AppSpacing.screenPaddingH,
        AppSpacing.md,
      ),
      child: Material(
        color: AppColors.brandGreenPrimary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        elevation: 4,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          onTap: () => context.push(RouteConstants.cart),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(Icons.shopping_cart_rounded,
                      color: AppColors.white, size: 18),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '$count ${count == 1 ? 'item' : 'items'}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  'View Cart · ${CurrencyFormatter.format(total)}',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const Icon(Icons.arrow_forward_rounded,
                    color: AppColors.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shimmer ───────────────────────────────────────────────────────────────────

class _ProductListShimmer extends StatelessWidget {
  const _ProductListShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingH,
        AppSpacing.md,
        AppSpacing.screenPaddingH,
        AppSpacing.md,
      ),
      itemCount: 8,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.lightSurfaceVariant,
        highlightColor: AppColors.lightOutlineVariant,
        child: Container(
          height: 84,
          decoration: BoxDecoration(
            color: AppColors.lightSurfaceVariant,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
    );
  }
}
