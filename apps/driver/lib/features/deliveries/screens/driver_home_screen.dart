import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

import '../../auth/providers/driver_auth_provider.dart';
import '../../location/driver_location_service.dart';
import '../models/delivery.dart';
import '../providers/delivery_provider.dart';

/// Driver home with bottom navigation: active deliveries, history, profile.
class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // Keep GPS running whenever there's an active job.
    ref.watch(locationTrackingProvider);

    const titles = ['My Deliveries', 'History', 'Profile'];

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.brandGreenPrimary,
        foregroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(titles[_index],
            style: const TextStyle(
                color: AppColors.white, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(myDeliveriesProvider);
              ref.invalidate(myHistoryProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [_ActiveTab(), _HistoryTab(), _ProfileTab()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: AppColors.lightSurface,
        indicatorColor: AppColors.brandGreenSurface,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.local_shipping_outlined),
              selectedIcon: Icon(Icons.local_shipping_rounded),
              label: 'Deliveries'),
          NavigationDestination(
              icon: Icon(Icons.history_rounded), label: 'History'),
          NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile'),
        ],
      ),
    );
  }
}

// ── Active deliveries tab (with stats) ──────────────────────────────────────

class _ActiveTab extends ConsumerWidget {
  const _ActiveTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(myDeliveriesProvider);
    final history = ref.watch(myHistoryProvider).valueOrNull ?? const [];

    final now = DateTime.now();
    final deliveredToday = history
        .where((d) =>
            d.deliveredAt != null &&
            d.deliveredAt!.year == now.year &&
            d.deliveredAt!.month == now.month &&
            d.deliveredAt!.day == now.day)
        .toList();
    final todayValue =
        deliveredToday.fold<int>(0, (s, d) => s + d.totalCents);

    return RefreshIndicator(
      color: AppColors.brandGreenPrimary,
      onRefresh: () async {
        ref.invalidate(myDeliveriesProvider);
        ref.invalidate(myHistoryProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Stats
          Row(
            children: [
              Expanded(
                  child: _StatCard(
                      icon: Icons.pending_actions_rounded,
                      label: 'Active',
                      value:
                          '${active.valueOrNull?.length ?? 0}')),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                  child: _StatCard(
                      icon: Icons.check_circle_rounded,
                      label: 'Delivered today',
                      value: '${deliveredToday.length}')),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                  child: _StatCard(
                      icon: Icons.payments_rounded,
                      label: "Today's value",
                      value: CurrencyFormatter.formatNoDecimals(todayValue))),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Active jobs',
              style: AppTypography.titleSmall
                  .copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.sm),
          active.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.brandGreenPrimary)),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Could not load deliveries.',
                  style: TextStyle(color: AppColors.lightOnSurfaceVariant)),
            ),
            data: (list) => list.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('No active deliveries right now.',
                          style: TextStyle(
                              color: AppColors.lightOnSurfaceVariant)),
                    ),
                  )
                : Column(
                    children: [
                      for (final d in list)
                        _DeliveryTile(delivery: d, active: true),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ── History tab ─────────────────────────────────────────────────────────────

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myHistoryProvider);
    return RefreshIndicator(
      color: AppColors.brandGreenPrimary,
      onRefresh: () async => ref.invalidate(myHistoryProvider),
      child: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.brandGreenPrimary)),
        error: (_, __) => ListView(children: const [
          SizedBox(height: 120),
          Center(child: Text('Could not load history.')),
        ]),
        data: (list) => list.isEmpty
            ? ListView(children: const [
                SizedBox(height: 120),
                Icon(Icons.history_rounded,
                    size: 56, color: AppColors.lightOnSurfaceVariant),
                SizedBox(height: 12),
                Center(
                    child: Text('No completed deliveries yet.',
                        style:
                            TextStyle(color: AppColors.lightOnSurfaceVariant))),
              ])
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: list.length,
                itemBuilder: (_, i) =>
                    _DeliveryTile(delivery: list[i], active: false),
              ),
      ),
    );
  }
}

// ── Profile tab ─────────────────────────────────────────────────────────────

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(driverCurrentUserProvider).valueOrNull;
    final history = ref.watch(myHistoryProvider).valueOrNull ?? const [];
    final totalValue = history.fold<int>(0, (s, d) => s + d.totalCents);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.md),
        Center(
          child: CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.brandGreenSurface,
            child: const Icon(Icons.delivery_dining_rounded,
                size: 40, color: AppColors.brandGreenPrimary),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Text(
              user?.displayName.isNotEmpty == true ? user!.displayName : 'Driver',
              style: AppTypography.titleMedium
                  .copyWith(fontWeight: FontWeight.w800)),
        ),
        if (user?.email != null)
          Center(
            child: Text(user!.email!,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.lightOnSurfaceVariant)),
          ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    icon: Icons.local_shipping_rounded,
                    label: 'Total delivered',
                    value: '${history.length}')),
            const SizedBox(width: AppSpacing.md),
            Expanded(
                child: _StatCard(
                    icon: Icons.payments_rounded,
                    label: 'Total value',
                    value: CurrencyFormatter.formatNoDecimals(totalValue))),
          ],
        ),
        const SizedBox(height: AppSpacing.x3l),
        SizedBox(
          height: AppSpacing.buttonHeight,
          child: OutlinedButton.icon(
            onPressed: () => driverSignOut(ref),
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            label: const Text('Log out',
                style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error)),
          ),
        ),
      ],
    );
  }
}

// ── Shared widgets ──────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.lightOutlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.brandGreenPrimary, size: 18),
          const SizedBox(height: 8),
          Text(value,
              style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.lightOnSurface)),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.lightOnSurfaceVariant)),
        ],
      ),
    );
  }
}

class _DeliveryTile extends StatelessWidget {
  const _DeliveryTile({required this.delivery, required this.active});
  final Delivery delivery;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          onTap: active
              ? () => context.push(
                    RouteConstants.driverDeliveryDetail
                        .replaceFirst(':deliveryId', delivery.orderId),
                    extra: delivery,
                  )
              : null,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.lightOutlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: (active
                            ? AppColors.brandGold
                            : AppColors.brandGreenPrimary)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    active ? Icons.local_shipping_rounded : Icons.check_rounded,
                    color: active
                        ? AppColors.brandGold
                        : AppColors.brandGreenPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('#${delivery.ref}',
                          style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.lightOnSurface)),
                      Text(
                        delivery.deliveryAddress.isNotEmpty
                            ? delivery.deliveryAddress
                            : (delivery.shopName.isNotEmpty
                                ? delivery.shopName
                                : '—'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                            color: AppColors.lightOnSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(CurrencyFormatter.format(delivery.totalCents),
                    style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.lightOnSurface)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
