import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';

import '../data/pools_repository.dart';
import '../providers/pools_provider.dart';
import 'pools_list_screen.dart' show PoolProgress;

class PoolDetailScreen extends ConsumerWidget {
  const PoolDetailScreen({super.key, required this.poolId, this.initial});
  final String poolId;
  final BuyingPool? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(poolProvider(poolId));
    final pool = async.valueOrNull ?? initial;
    final myQty = ref.watch(myPoolQtyProvider(poolId)).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Buying Pool'),
        backgroundColor: AppColors.brandGreenPrimary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: pool == null
          ? (async.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.brandGreenPrimary))
              : const Center(child: Text('Pool not found.')))
          : RefreshIndicator(
              color: AppColors.brandGreenPrimary,
              onRefresh: () async {
                ref.invalidate(poolProvider(poolId));
                ref.invalidate(myPoolQtyProvider(poolId));
              },
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _Header(pool: pool),
                  const SizedBox(height: AppSpacing.lg),
                  _PriceCard(pool: pool),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(color: AppColors.lightOutlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${pool.totalQty} units pooled',
                                style: AppTypography.titleMedium
                                    .copyWith(fontWeight: FontWeight.w800)),
                            Text('${pool.memberCount} shops',
                                style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.lightOnSurfaceVariant)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        PoolProgress(pool: pool),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (myQty != null)
                    _MyPledge(pool: pool, myQty: myQty)
                  else
                    _JoinCta(pool: pool),
                  const SizedBox(height: AppSpacing.x3l),
                ],
              ),
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.pool});
  final BuyingPool pool;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            width: 72,
            height: 72,
            color: AppColors.white,
            child: pool.productImage.isEmpty
                ? const Icon(Icons.inventory_2_outlined,
                    color: AppColors.brandGreenPrimary, size: 30)
                : CachedNetworkImage(
                    imageUrl: pool.productImage, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pool.productName,
                  style: AppTypography.titleMedium
                      .copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(_timeLeft(pool),
                  style: AppTypography.bodySmall.copyWith(
                      color: pool.timeLeft.inHours < 12
                          ? AppColors.error
                          : AppColors.lightOnSurfaceVariant,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  static String _timeLeft(BuyingPool p) {
    final d = p.timeLeft;
    if (d.isNegative) return 'Closing now';
    if (d.inDays > 0) return 'Closes in ${d.inDays}d ${d.inHours % 24}h';
    if (d.inHours > 0) return 'Closes in ${d.inHours}h ${d.inMinutes % 60}m';
    return 'Closes in ${d.inMinutes}m';
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.pool});
  final BuyingPool pool;
  @override
  Widget build(BuildContext context) {
    final hasDiscount = pool.discountPct > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF066837), Color(0xFF0B8F47)]),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pool price / unit',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.white.withValues(alpha: 0.85))),
              const SizedBox(height: 4),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(CurrencyFormatter.format(pool.discountedUnitCents),
                    style: AppTypography.titleLarge.copyWith(
                        color: AppColors.white, fontWeight: FontWeight.w800)),
                if (hasDiscount) ...[
                  const SizedBox(width: 8),
                  Text(CurrencyFormatter.format(pool.unitPriceCents),
                      style: AppTypography.bodySmall.copyWith(
                          color: AppColors.white.withValues(alpha: 0.75),
                          decoration: TextDecoration.lineThrough)),
                ],
              ]),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 6),
            decoration: BoxDecoration(
                color: AppColors.brandGold,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull)),
            child: Text(hasDiscount ? '${pool.discountPct}% OFF' : 'No discount yet',
                style: AppTypography.labelSmall.copyWith(
                    color: const Color(0xFF1a1400),
                    fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _JoinCta extends ConsumerWidget {
  const _JoinCta({required this.pool});
  final BuyingPool pool;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: pool.isOpen
            ? () => _showJoinSheet(context, ref, pool, current: 0)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandGreenPrimary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        ),
        icon: const Icon(Icons.group_add_rounded),
        label: Text(pool.isOpen ? 'Join this pool' : 'Pool closed'),
      ),
    );
  }
}

class _MyPledge extends ConsumerWidget {
  const _MyPledge({required this.pool, required this.myQty});
  final BuyingPool pool;
  final int myQty;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.brandGreenSurfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.brandGreenPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.brandGreenPrimary, size: 20),
            const SizedBox(width: 8),
            Text('You pledged $myQty units',
                style: AppTypography.titleSmall
                    .copyWith(fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 4),
          Text(
            'Your share: ${CurrencyFormatter.format(pool.discountedUnitCents * myQty)} '
            'at ${pool.discountPct}% off',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.lightOnSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: pool.isOpen
                    ? () =>
                        _showJoinSheet(context, ref, pool, current: myQty)
                    : null,
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandGreenPrimary,
                    side: const BorderSide(
                        color: AppColors.brandGreenPrimary)),
                child: const Text('Change pledge'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            TextButton(
              onPressed: () async {
                await ref
                    .read(poolsRepositoryProvider)
                    .leavePool(pool.id);
                _refresh(ref, pool.id);
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Leave'),
            ),
          ]),
        ],
      ),
    );
  }
}

void _refresh(WidgetRef ref, String poolId) {
  ref.invalidate(poolProvider(poolId));
  ref.invalidate(myPoolQtyProvider(poolId));
  ref.invalidate(openPoolsProvider);
}

Future<void> _showJoinSheet(
  BuildContext context,
  WidgetRef ref,
  BuyingPool pool, {
  required int current,
}) async {
  var qty = current > 0 ? current : 10;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl,
            AppSpacing.xl + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(current > 0 ? 'Change your pledge' : 'How many units?',
                style: AppTypography.titleMedium
                    .copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('${pool.productName} · ${CurrencyFormatter.format(pool.unitPriceCents)}/unit',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.lightOnSurfaceVariant)),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StepBtn(
                    icon: Icons.remove_rounded,
                    onTap: () =>
                        setState(() => qty = (qty - 5).clamp(1, 100000))),
                SizedBox(
                  width: 90,
                  child: Text('$qty',
                      textAlign: TextAlign.center,
                      style: AppTypography.headlineSmall
                          .copyWith(fontWeight: FontWeight.w800)),
                ),
                _StepBtn(
                    icon: Icons.add_rounded,
                    onTap: () => setState(() => qty += 5)),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  await ref
                      .read(poolsRepositoryProvider)
                      .joinPool(poolId: pool.id, quantity: qty);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _refresh(ref, pool.id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandGreenPrimary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd)),
                ),
                child: Text(current > 0 ? 'Update pledge' : 'Join with $qty units'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
            color: AppColors.brandGreenSurface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        child: Icon(icon, color: AppColors.brandGreenPrimary),
      ),
    );
  }
}
