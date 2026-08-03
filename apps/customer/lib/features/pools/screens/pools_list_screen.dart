import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

import '../data/pools_repository.dart';
import '../providers/pools_provider.dart';

class PoolsListScreen extends ConsumerWidget {
  const PoolsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(openPoolsProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Buying Pools'),
        backgroundColor: AppColors.brandGreenPrimary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppColors.brandGreenPrimary,
        onRefresh: () async => ref.invalidate(openPoolsProvider),
        child: async.when(
          loading: () => const Center(
              child:
                  CircularProgressIndicator(color: AppColors.brandGreenPrimary)),
          error: (e, _) => ListView(children: [
            const SizedBox(height: 120),
            Center(
                child: Text('Could not load pools.\n$e',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.lightOnSurfaceVariant))),
          ]),
          data: (pools) {
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                const _HowItWorks(),
                const SizedBox(height: AppSpacing.lg),
                if (pools.isEmpty)
                  const _EmptyPools()
                else
                  for (final p in pools) ...[
                    PoolCard(pool: p),
                    const SizedBox(height: AppSpacing.md),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Reusable pool card (used on the Pools list and the Home screen).
class PoolCard extends StatelessWidget {
  const PoolCard({super.key, required this.pool});
  final BuyingPool pool;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      onTap: () => context.push('/pools/${pool.id}', extra: pool),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.lightOutlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _thumb(pool.productImage),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pool.productName,
                          style: AppTypography.bodyMedium
                              .copyWith(fontWeight: FontWeight.w700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('${pool.memberCount} shops · ${_timeLeft(pool)}',
                          style: AppTypography.labelSmall.copyWith(
                              color: AppColors.lightOnSurfaceVariant)),
                    ],
                  ),
                ),
                _DiscountBadge(pct: pool.discountPct),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            PoolProgress(pool: pool),
          ],
        ),
      ),
    );
  }

  Widget _thumb(String url) {
    const size = 56.0;
    Widget fallback() => Container(
          width: size,
          height: size,
          color: AppColors.brandGreenSurfaceLight,
          child: const Icon(Icons.inventory_2_outlined,
              color: AppColors.brandGreenPrimary, size: 24),
        );
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: url.isEmpty
          ? fallback()
          : Container(
              width: size,
              height: size,
              color: AppColors.white,
              child: CachedNetworkImage(
                  imageUrl: url,
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => fallback())),
    );
  }

  static String _timeLeft(BuyingPool p) {
    final d = p.timeLeft;
    if (d.isNegative) return 'closing';
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h left';
    if (d.inHours > 0) return '${d.inHours}h left';
    return '${d.inMinutes}m left';
  }
}

/// Progress bar toward the next discount tier (or the creator's target).
class PoolProgress extends StatelessWidget {
  const PoolProgress({super.key, required this.pool});
  final BuyingPool pool;

  @override
  Widget build(BuildContext context) {
    final total = pool.totalQty;
    final nextAt = pool.nextTierAt; // 0 if already max
    final atMax = nextAt == 0;
    // Progress bar fills toward the next tier (or target if past 150).
    final ceiling = atMax ? pool.targetQty : nextAt;
    final ratio = ceiling <= 0 ? 1.0 : (total / ceiling).clamp(0.0, 1.0);

    final label = atMax
        ? 'Max 15% reached · $total / ${pool.targetQty} to target'
        : '$total items · ${nextAt - total} more for ${pool.nextTierPct}% off';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: AppColors.lightSurfaceVariant,
            valueColor: const AlwaysStoppedAnimation(AppColors.brandGold),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.lightOnSurfaceVariant)),
            _TierPips(total: total),
          ],
        ),
      ],
    );
  }
}

class _TierPips extends StatelessWidget {
  const _TierPips({required this.total});
  final int total;
  @override
  Widget build(BuildContext context) {
    Widget pip(int at, String label) {
      final on = total >= at;
      return Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Text(label,
            style: AppTypography.labelSmall.copyWith(
              color: on ? AppColors.brandGreenPrimary : AppColors.lightOutline,
              fontWeight: on ? FontWeight.w800 : FontWeight.w600,
            )),
      );
    }

    return Row(children: [pip(50, '5%'), pip(100, '10%'), pip(150, '15%')]);
  }
}

class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge({required this.pct});
  final int pct;
  @override
  Widget build(BuildContext context) {
    final active = pct > 0;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 5),
      decoration: BoxDecoration(
        color: active
            ? AppColors.brandGreenPrimary
            : AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(active ? '$pct% OFF' : 'Join to save',
          style: AppTypography.labelSmall.copyWith(
              color: active ? AppColors.white : AppColors.lightOnSurfaceVariant,
              fontWeight: FontWeight.w800)),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF066837), Color(0xFF0B8F47)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Buy together, save together',
              style: AppTypography.titleMedium.copyWith(
                  color: AppColors.white, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            'Pool the same item with other shops. The more units the pool reaches, the bigger everyone\'s discount:',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.white.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(spacing: 8, runSpacing: 8, children: const [
            _Tier('50 items', '5% off'),
            _Tier('100 items', '10% off'),
            _Tier('150 items', '15% off'),
          ]),
        ],
      ),
    );
  }
}

class _Tier extends StatelessWidget {
  const _Tier(this.qty, this.off);
  final String qty;
  final String off;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text('$qty → $off',
          style: AppTypography.labelSmall.copyWith(
              color: AppColors.white, fontWeight: FontWeight.w700)),
    );
  }
}

class _EmptyPools extends StatelessWidget {
  const _EmptyPools();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(children: [
        const Icon(Icons.groups_outlined, size: 64, color: AppColors.lightOutline),
        const SizedBox(height: AppSpacing.md),
        Text('No open pools yet',
            style: AppTypography.titleMedium
                .copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Start one from any product — add 50+ units to open a pool.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.lightOnSurfaceVariant)),
      ]),
    );
  }
}
