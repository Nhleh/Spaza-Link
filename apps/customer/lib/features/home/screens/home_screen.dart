import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:spazalink_core/core.dart';

import '../../auth/providers/auth_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../categories/providers/category_provider.dart';
import '../../categories/widgets/category_card.dart';
import '../../products/providers/product_provider.dart';
import '../../products/widgets/product_card.dart';
import '../../sync/providers/sync_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(currentShopProvider);
    final shop = shopAsync.valueOrNull;
    final shopId = shop?.id ?? '';

    final cartCount = ref.watch(cartItemCountProvider(shopId));
    final syncState = ref.watch(syncStateProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: _HomeAppBar(cartCount: cartCount, shopId: shopId),
      body: Column(
        children: [
          // Offline banner
          const _ConnectivityBanner(),
          // Sync pending nudge
          if (syncState == SyncState.syncing)
            _InfoStrip(
              icon: Icons.sync_rounded,
              message: 'Syncing your offline orders…',
              color: AppColors.syncSyncing,
            )
          else if (syncState == SyncState.failed)
            _InfoStrip(
              icon: Icons.warning_amber_rounded,
              message: 'Some orders failed to sync. Tap to retry.',
              color: AppColors.syncFailed,
              onTap: () => ref.read(syncServiceProvider).syncNow(),
            ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.brandGreenPrimary,
              onRefresh: () async {
                ref.invalidate(categoriesProvider);
                ref.invalidate(featuredProductsProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: AppSpacing.x4l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    _GreetingSection(shop: shop),

                    // Featured Banner
                    const _FeaturedBanner(),

                    // Shop by Category
                    const SizedBox(height: AppSpacing.x3l),
                    _SectionHeader(
                      title: 'Shop by Category',
                      onSeeAll: () => context.go(RouteConstants.catalogue),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _CategoryRow(),

                    // Featured Products
                    const SizedBox(height: AppSpacing.x3l),
                    _SectionHeader(
                      title: 'Featured Products',
                      onSeeAll: () => context.go(RouteConstants.catalogue),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _FeaturedProductsGrid(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── App Bar ───────────────────────────────────────────────────────────────────

class _HomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const _HomeAppBar({required this.cartCount, required this.shopId});

  final int cartCount;
  final String shopId;

  @override
  Size get preferredSize => const Size.fromHeight(AppSpacing.appBarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: AppColors.brandGreenPrimary,
      foregroundColor: AppColors.white,
      elevation: 0,
      titleSpacing: AppSpacing.lg,
      title: const Text(
        'SpazaLink',
        style: TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w800,
          fontSize: 22,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: () => context.push(RouteConstants.helpCentre),
          tooltip: 'Search',
        ),
        _CartIconButton(count: cartCount),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }
}

class _CartIconButton extends StatelessWidget {
  const _CartIconButton({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined),
          onPressed: () => context.go(RouteConstants.cart),
          tooltip: 'Cart',
        ),
        if (count > 0)
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
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Connectivity Banner ───────────────────────────────────────────────────────

class _ConnectivityBanner extends ConsumerWidget {
  const _ConnectivityBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    if (isOnline) return const SizedBox.shrink();
    return const OfflineBanner();
  }
}

// ── Greeting ──────────────────────────────────────────────────────────────────

class _GreetingSection extends StatelessWidget {
  const _GreetingSection({this.shop});
  final ShopModel? shop;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingH,
        AppSpacing.xxl,
        AppSpacing.screenPaddingH,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_greeting}, ${shop?.ownerName.split(' ').first ?? 'there'}! 👋',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.lightOnSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            shop?.shopName ?? 'Your Store',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.lightOnSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Featured Banner ───────────────────────────────────────────────────────────

class _FeaturedBanner extends StatefulWidget {
  const _FeaturedBanner();

  @override
  State<_FeaturedBanner> createState() => _FeaturedBannerState();
}

class _FeaturedBannerState extends State<_FeaturedBanner> {
  final _controller = PageController();
  int _page = 0;
  Timer? _timer;

  // Placeholder banners — replaced with Firestore banners in Phase 8.
  static const _banners = [
    _BannerData(
      gradient: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
      icon: Icons.local_offer_rounded,
      title: 'Bulk Savings Await',
      subtitle: 'Stock up and save more per unit on every order.',
    ),
    _BannerData(
      gradient: [Color(0xFFF57C00), Color(0xFFF9A825)],
      icon: Icons.delivery_dining_rounded,
      title: 'Free Delivery Over R1,750',
      subtitle: 'Order more, pay less. Free delivery on big orders.',
    ),
    _BannerData(
      gradient: [Color(0xFF1565C0), Color(0xFF42A5F5)],
      icon: Icons.wifi_off_rounded,
      title: 'Order Offline Too',
      subtitle: 'No connection? Your orders are saved and sent automatically.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_page + 1) % _banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (p) => setState(() => _page = p),
            itemCount: _banners.length,
            itemBuilder: (_, i) => _BannerSlide(data: _banners[i]),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _page == i ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _page == i
                    ? AppColors.brandGreenPrimary
                    : AppColors.lightOutline,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerData {
  const _BannerData({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final List<Color> gradient;
  final IconData icon;
  final String title;
  final String subtitle;
}

class _BannerSlide extends StatelessWidget {
  const _BannerSlide({required this.data});
  final _BannerData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: data.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data.title,
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    data.subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.white.withValues(alpha: 0.88),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Icon(data.icon, color: AppColors.white.withValues(alpha: 0.3), size: 56),
          ],
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});
  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.brandGreenPrimary,
              padding: EdgeInsets.zero,
            ),
            child: const Text('See all →'),
          ),
        ],
      ),
    );
  }
}

// ── Category Row ──────────────────────────────────────────────────────────────

class _CategoryRow extends ConsumerWidget {
  const _CategoryRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return SizedBox(
      height: 100,
      child: categoriesAsync.when(
        loading: () => _shimmerRow(),
        error: (_, __) => const SizedBox.shrink(),
        data: (cats) {
          if (cats.isEmpty) return const SizedBox.shrink();
          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingH,
            ),
            scrollDirection: Axis.horizontal,
            itemCount: cats.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppSpacing.md),
            itemBuilder: (_, i) => SizedBox(
              width: 76,
              child: CategoryCard(category: cats[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _shimmerRow() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
      scrollDirection: Axis.horizontal,
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.lightSurfaceVariant,
        highlightColor: AppColors.lightOutlineVariant,
        child: Container(
          width: 76,
          decoration: BoxDecoration(
            color: AppColors.lightSurfaceVariant,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
    );
  }
}

// ── Featured Products Grid ────────────────────────────────────────────────────

class _FeaturedProductsGrid extends ConsumerWidget {
  const _FeaturedProductsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(featuredProductsProvider);

    return productsAsync.when(
      loading: () => _shimmerGrid(),
      error: (_, __) => const SizedBox.shrink(),
      data: (products) {
        if (products.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingH,
            ),
            child: const EmptyStateWidget(
              type: EmptyStateType.noProducts,
              compact: true,
            ),
          );
        }
        final visible = products.take(6).toList();
        return GridView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingH,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.62,
          ),
          itemCount: visible.length,
          itemBuilder: (_, i) => ProductCard(product: visible[i]),
        );
      },
    );
  }

  Widget _shimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.62,
      ),
      itemCount: 4,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.lightSurfaceVariant,
        highlightColor: AppColors.lightOutlineVariant,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.lightSurfaceVariant,
            borderRadius: BorderRadius.circular(AppSpacing.productCardRadius),
          ),
        ),
      ),
    );
  }
}

// ── Info strip ────────────────────────────────────────────────────────────────

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({
    required this.icon,
    required this.message,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String message;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        color: color.withValues(alpha: 0.1),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTypography.labelSmall.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
