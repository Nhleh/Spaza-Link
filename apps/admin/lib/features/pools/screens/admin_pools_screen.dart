import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';

import '../data/admin_pools_repository.dart';
import '../providers/admin_pools_provider.dart';

class AdminPoolsScreen extends ConsumerWidget {
  const AdminPoolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminPoolsProvider);

    return Scaffold(
      backgroundColor: AppColors.adminDarkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.adminDarkSurface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Buying Pools',
            style: TextStyle(
                color: AppColors.darkOnSurface, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.darkOnSurface),
            onPressed: () => ref.invalidate(adminPoolsProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: async.when(
        loading: () => const Center(
            child:
                CircularProgressIndicator(color: AppColors.brandGreenPrimary)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load pools.\n$e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.darkOnSurfaceVariant)),
          ),
        ),
        data: (pools) {
          if (pools.isEmpty) {
            return const Center(
              child: Text('No buying pools yet.',
                  style: TextStyle(color: AppColors.darkOnSurfaceVariant)),
            );
          }
          final open = pools.where((p) => p.effectiveStatus == 'open').length;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(children: [
                _Stat(label: 'Total pools', value: '${pools.length}'),
                const SizedBox(width: 16),
                _Stat(label: 'Active', value: '$open'),
              ]),
              const SizedBox(height: 20),
              for (final p in pools) ...[
                _PoolCard(pool: p),
                const SizedBox(height: 14),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.adminDarkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.adminDarkOutline, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: const TextStyle(
                color: AppColors.darkOnSurface,
                fontSize: 22,
                fontWeight: FontWeight.w800)),
        Text(label,
            style: const TextStyle(
                color: AppColors.darkOnSurfaceVariant, fontSize: 12)),
      ]),
    );
  }
}

class _PoolCard extends ConsumerWidget {
  const _PoolCard({required this.pool});
  final AdminPool pool;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ceiling =
        pool.totalQty >= 150 ? pool.targetQty : (pool.nextTierCeiling);
    final ratio =
        ceiling <= 0 ? 1.0 : (pool.totalQty / ceiling).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.adminDarkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.adminDarkOutline, width: 0.5),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.darkOnSurfaceVariant,
          collapsedIconColor: AppColors.darkOnSurfaceVariant,
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
          title: Row(
            children: [
              Expanded(
                child: Text(pool.productName,
                    style: const TextStyle(
                        color: AppColors.darkOnSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
              _StatusChip(status: pool.effectiveStatus),
              const SizedBox(width: 8),
              _DiscountChip(pct: pool.discountPct),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'by ${pool.creatorName} · ${pool.memberCount} shops · '
                  '${pool.totalQty}/${pool.targetQty} units · ${_timeLeft(pool)}',
                  style: const TextStyle(
                      color: AppColors.darkOnSurfaceVariant, fontSize: 12),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 7,
                    backgroundColor: AppColors.adminDarkSurfaceVariant,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.brandGold),
                  ),
                ),
              ],
            ),
          ),
          children: [
            Consumer(builder: (context, ref, _) {
              final m = ref.watch(adminPoolMembersProvider(pool.id));
              return m.when(
                loading: () => const Padding(
                    padding: EdgeInsets.all(8),
                    child: LinearProgressIndicator()),
                error: (e, _) => Text('Members error: $e',
                    style: const TextStyle(color: AppColors.error)),
                data: (members) => Column(
                  children: [
                    for (final mm in members)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(mm.name,
                                style: const TextStyle(
                                    color: AppColors.darkOnSurface,
                                    fontSize: 13)),
                            Text('${mm.quantity} units',
                                style: const TextStyle(
                                    color: AppColors.darkOnSurfaceVariant,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  static String _timeLeft(AdminPool p) {
    if (p.effectiveStatus != 'open') return p.effectiveStatus;
    final d = p.timeLeft;
    if (d.isNegative) return 'closing';
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h left';
    if (d.inHours > 0) return '${d.inHours}h left';
    return '${d.inMinutes}m left';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'open' => AppColors.brandGreenPrimary,
      'fulfilled' => AppColors.statusDelivered,
      'expired' => AppColors.brandGold,
      _ => AppColors.error,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}

class _DiscountChip extends StatelessWidget {
  const _DiscountChip({required this.pct});
  final int pct;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: pct > 0
              ? AppColors.brandGreenPrimary
              : AppColors.adminDarkSurfaceVariant,
          borderRadius: BorderRadius.circular(20)),
      child: Text(pct > 0 ? '$pct% off' : '—',
          style: TextStyle(
              color: pct > 0 ? AppColors.white : AppColors.darkOnSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w800)),
    );
  }
}

extension on AdminPool {
  int get nextTierCeiling => totalQty < 50
      ? 50
      : totalQty < 100
          ? 100
          : 150;
}
