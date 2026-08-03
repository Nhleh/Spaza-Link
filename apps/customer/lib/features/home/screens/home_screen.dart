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

                    // Savings value-prop hero
                    const SizedBox(height: AppSpacing.md),
                    const _SavingsBanner(),

                    // Next delivery card (with truck)
                    const SizedBox(height: AppSpacing.lg),
                    _NextDeliveryCard(shop: shop),

                    // Shop by Category
                    const SizedBox(height: AppSpacing.x3l),
                    _SectionHeader(
                      title: 'Shop by Category',
                      onSeeAll: () => context.go(RouteConstants.catalogue),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _CategoryRow(),

                    // Top Deals
                    const SizedBox(height: AppSpacing.x3l),
                    _SectionHeader(
                      title: 'Top Deals',
                      onSeeAll: () => context.go(RouteConstants.catalogue),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _FeaturedProductsGrid(),

                    // Active buying pools (below Top Deals)
                    const SizedBox(height: AppSpacing.x3l),
                    const _BuyingPoolsCard(),
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
          onPressed: () => context.push(RouteConstants.cart),
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

// ── Savings Banner ────────────────────────────────────────────────────────────

/// Green value-prop hero, matching the mockup's savings card. Honest copy — no
/// fabricated figures until real order history exists to compute savings from.
class _SavingsBanner extends StatelessWidget {
  const _SavingsBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandGreenPrimary.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buy in bulk, save more',
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Wholesale prices delivered to your shop. '
                    'The more you order, the less you pay per unit.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.white.withValues(alpha: 0.9),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Icon(
              Icons.savings_rounded,
              color: AppColors.white.withValues(alpha: 0.28),
              size: 56,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Next Delivery Card ────────────────────────────────────────────────────────

/// White card with the delivery truck, matching mockup screen 4. Reflects the
/// real shop status — no fake delivery dates.
class _NextDeliveryCard extends StatelessWidget {
  const _NextDeliveryCard({this.shop});
  final ShopModel? shop;

  ({String title, String subtitle}) get _status {
    if (shop == null) {
      return (
        title: 'Next delivery',
        subtitle: 'Register your shop to schedule deliveries',
      );
    }
    final approved = shop!.status == 'approved';
    if (!approved) {
      return (
        title: 'Shop pending approval',
        subtitle: 'Deliveries unlock once an admin approves your shop',
      );
    }
    return (
      title: 'No delivery scheduled',
      subtitle: 'Place an order and we\'ll schedule your delivery',
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _status;
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          onTap: () => context.go(RouteConstants.orders),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.lightOutlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.brandGreenPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: AppColors.brandGreenPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.title,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.lightOnSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.lightOnSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.lightOnSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Buying Pools promo ────────────────────────────────────────────────────────

class _BuyingPoolsCard extends StatelessWidget {
  const _BuyingPoolsCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
      child: Material(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          onTap: () => context.push('/pools'),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF066837), Color(0xFF0B8F47)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(Icons.groups_rounded,
                      color: AppColors.white, size: 26),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Active Buying Pools',
                          style: AppTypography.titleSmall.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text('Team up with other shops — up to 15% off',
                          style: AppTypography.bodySmall.copyWith(
                              color: AppColors.white.withValues(alpha: 0.9))),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.white),
              ],
            ),
          ),
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
