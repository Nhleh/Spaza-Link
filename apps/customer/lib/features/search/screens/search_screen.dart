import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';

import '../../auth/providers/auth_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../products/widgets/product_grid.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _ctrl;
  final FocusNode _focus = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialQuery);
    _query = widget.initialQuery;
    if (widget.initialQuery.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
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
        titleSpacing: 0,
        leading: const BackButton(color: AppColors.white),
        title: _SearchField(
          controller: _ctrl,
          focusNode: _focus,
          onChanged: (v) => setState(() => _query = v),
          onClear: () {
            _ctrl.clear();
            setState(() => _query = '');
          },
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () {
                  Navigator.of(context).pop();
                  // parent shell handles navigation to cart tab
                },
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
      body: _query.trim().isEmpty
          ? const _SearchHints()
          : _SearchResults(query: _query.trim()),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.lightOnSurface,
        ),
        decoration: InputDecoration(
          hintText: 'Search products…',
          hintStyle: const TextStyle(
            color: AppColors.lightOnSurfaceVariant,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.lightOnSurfaceVariant,
            size: 18,
          ),
          suffixIcon: ListenableBuilder(
            listenable: controller,
            builder: (_, __) => controller.text.isEmpty
                ? const SizedBox.shrink()
                : GestureDetector(
                    onTap: onClear,
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.lightOnSurfaceVariant,
                      size: 18,
                    ),
                  ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

class _SearchHints extends StatelessWidget {
  const _SearchHints();

  static const _suggestions = [
    'Beverages',
    'Chips & Snacks',
    'Cooking Oil',
    'Bread & Bakery',
    'Dairy',
    'Cleaning Products',
    'Tobacco',
    'Candy',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text(
            'Popular searches',
            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _suggestions
                .map(
                  (s) => ActionChip(
                    label: Text(s),
                    labelStyle: AppTypography.bodySmall.copyWith(
                      color: AppColors.brandGreenPrimary,
                    ),
                    backgroundColor: AppColors.brandGreenSurface,
                    side: const BorderSide(color: AppColors.brandGreenLight),
                    onPressed: () {
                      // Let the parent state know via callback — not possible
                      // without a controller so we use a pattern of pushing
                      // a new route with the query instead.
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => SearchScreen(initialQuery: s),
                        ),
                      );
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.query});
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(productSearchProvider(query));

    return resultsAsync.when(
      loading: () => ProductGrid(
        products: const [],
        isLoading: true,
        padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
      ),
      error: (e, _) => EmptyStateWidget(
        type: EmptyStateType.error,
        message: 'Search failed. Please try again.',
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(productSearchProvider(query)),
      ),
      data: (products) {
        if (products.isEmpty) {
          return EmptyStateWidget(
            type: EmptyStateType.searchEmpty,
            message: 'No products found for "$query"',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPaddingH,
                AppSpacing.lg,
                AppSpacing.screenPaddingH,
                AppSpacing.sm,
              ),
              child: Text(
                '${products.length} result${products.length == 1 ? '' : 's'} for "$query"',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.lightOnSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: ProductGrid(
                products: products,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPaddingH,
                  0,
                  AppSpacing.screenPaddingH,
                  AppSpacing.screenPaddingH,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
