import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:spazalink_core/core.dart';

import '../../auth/providers/auth_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../categories/providers/category_provider.dart';
import '../../orders/providers/order_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../products/widgets/product_card.dart';
import '../../savings/models/savings.dart';
import '../../savings/providers/savings_provider.dart';
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
                    const SizedBox(height: AppSpacing.lg),

                    // Savings card ("You saved")
                    const _SavingsCard(),

                    // Next delivery card (with truck)
                    const SizedBox(height: AppSpacing.lg),
                    _NextDeliveryCard(shop: shop),

                    // Shop Now — large category tiles
                    const SizedBox(height: AppSpacing.x3l),
                    _SectionHeader(
                      title: 'Shop Now',
                      onSeeAll: () => context.go(RouteConstants.catalogue),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _CategoryGrid(),

                    // Top Deals
                    const SizedBox(height: AppSpacing.x3l),
                    const _TopDealsSection(),

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
  Size get preferredSize => const Size.fromHeight(72);

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shop = ref.watch(currentShopProvider).valueOrNull;
    final firstName = shop?.ownerName.split(' ').first ?? 'there';

    return AppBar(
      backgroundColor: AppColors.brandGreenPrimary,
      foregroundColor: AppColors.white,
      elevation: 0,
      toolbarHeight: 72,
      automaticallyImplyLeading: false,
      titleSpacing: AppSpacing.lg,
      // Greeting lives in the green header (reference screen 4).
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_greeting()}, $firstName! 👋',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: -0.2,
            ),
          ),
          Text(
            shop?.shopName ?? 'Your Store',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.85),
              fontSize: 12.5,
            ),
          ),
        ],
      ),
      actions: [
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

// ── Savings Card ──────────────────────────────────────────────────────────────

/// Green "You saved" card (reference screen 4). Shows the customer's real
/// savings for the chosen window (weekly/monthly — set in Settings); tapping
/// opens the detailed Savings Report.
class _SavingsCard extends ConsumerWidget {
  const _SavingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(savingsPeriodProvider);
    final data = ref.watch(savingsDataProvider).valueOrNull;
    final summary =
        period == SavingsPeriod.weekly ? data?.weekly : data?.monthly;
    final savedCents = summary?.totalCents ?? 0;
    final periodWord =
        period == SavingsPeriod.weekly ? 'this week' : 'this month';

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF066837), Color(0xFF0B8F47)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandGreenPrimary.withValues(alpha: 0.30),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl, vertical: AppSpacing.xl),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'You saved $periodWord',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(savedCents),
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    savedCents > 0
                        ? 'Tap to see your full savings report'
                        : 'Buy deals & pool to start saving',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            InkWell(
              onTap: () => context.push(RouteConstants.savings),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View details',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.white, size: 18),
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

// ── Next Delivery Card ────────────────────────────────────────────────────────

/// White "Next Delivery" card driven by the customer's real order status
/// (spec #12–#14). A confirmed order shows its status, expected delivery
/// (within 18h of confirmation) and remaining time; with no confirmed order on
/// the way it shows "No Delivery". Completed/cancelled orders never appear.
class _NextDeliveryCard extends ConsumerWidget {
  const _NextDeliveryCard({this.shop});
  final ShopModel? shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopId = shop?.id ?? '';
    final order =
        shopId.isEmpty ? null : ref.watch(nextDeliveryProvider(shopId));

    final bool hasDelivery = order != null;
    final eta = order == null ? null : deliveryEta(order);
    final remaining = eta == null ? null : eta.difference(DateTime.now());

    final String title = hasDelivery ? 'Next Delivery' : 'No Delivery';
    final String primary = hasDelivery
        ? DateFormat('EEEE, d MMMM').format(eta!)
        : 'No orders on the way';
    final String secondary = hasDelivery
        ? _remainingLabel(order.status, remaining!)
        : 'Your next delivery will appear here';

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
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.md, AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.lightOutlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.lightOnSurface,
                            ),
                          ),
                          if (hasDelivery) ...[
                            const SizedBox(width: AppSpacing.sm),
                            _StatusChip(status: order.status),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        primary,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.lightOnSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        secondary,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.lightOnSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                SizedBox(
                  width: 104,
                  height: 68,
                  child: Image.asset(
                    'assets/images/Couriers.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.centerRight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _remainingLabel(String status, Duration remaining) {
    if (status == OrderStatus.outForDelivery) return 'Out for delivery now';
    if (remaining.isNegative) return 'Arriving any moment';
    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;
    if (h >= 1) return 'Arrives in about ${h}h ${m}m';
    return 'Arrives in about ${remaining.inMinutes}m';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: status.orderStatusColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        status.orderStatusLabel,
        style: AppTypography.labelSmall.copyWith(
          color: status.orderStatusColor,
          fontWeight: FontWeight.w700,
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
            child: const Text('View all'),
          ),
        ],
      ),
    );
  }
}

// ── Shop Now — large category grid (4 columns) ────────────────────────────────

class _CategoryGrid extends ConsumerWidget {
  const _CategoryGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      loading: () => _shimmerGrid(),
      error: (_, __) => const SizedBox.shrink(),
      data: (cats) {
        if (cats.isEmpty) return const SizedBox.shrink();
        final visible = cats.take(8).toList(); // 4 × 2
        return GridView.builder(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingH),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.lg,
            mainAxisExtent: 82,
          ),
          itemCount: visible.length,
          itemBuilder: (_, i) => _CategoryTile(category: visible[i]),
        );
      },
    );
  }

  Widget _shimmerGrid() {
    return GridView.builder(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.lg,
        mainAxisExtent: 82,
      ),
      itemCount: 8,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.lightSurfaceVariant,
        highlightColor: AppColors.lightOutlineVariant,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.lightSurfaceVariant,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});
  final CategoryModel category;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        RouteConstants.catalogueCategory
            .replaceFirst(':categoryId', category.id),
        extra: category,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.brandGreenSurface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.lightOutlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: category.iconUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: category.iconUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.category_rounded,
                      color: AppColors.brandGreenPrimary,
                      size: 22,
                    ),
                  )
                : const Icon(
                    Icons.category_rounded,
                    color: AppColors.brandGreenPrimary,
                    size: 22,
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.lightOnSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Featured Products Grid ────────────────────────────────────────────────────

/// Top Deals: header with a 'View More' shown only when there are more than the
/// six shown on the dashboard, then the 6-item grid.
class _TopDealsSection extends ConsumerWidget {
  const _TopDealsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count =
        ref.watch(featuredProductsProvider).valueOrNull?.length ?? 0;
    final hasMore = count > 6;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingH),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Top Deals',
                  style: AppTypography.titleMedium
                      .copyWith(fontWeight: FontWeight.w700)),
              if (hasMore)
                TextButton(
                  onPressed: () => context.push('/top-deals'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.brandGreenPrimary,
                      padding: EdgeInsets.zero),
                  child: const Text('View More →'),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const _FeaturedProductsGrid(),
      ],
    );
  }
}

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
            crossAxisCount: 3,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.md,
            mainAxisExtent: 238,
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
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.md,
        mainAxisExtent: 238,
      ),
      itemCount: 6,
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
