import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/admin_drivers_repository.dart';
import '../providers/admin_drivers_provider.dart';

/// Driver detail: current delivery + live location, today's deliveries, and the
/// full list of orders they've delivered.
class AdminDriverDetailScreen extends ConsumerWidget {
  const AdminDriverDetailScreen({super.key, required this.driver});

  final DriverInfo driver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(driverOrdersProvider(driver.id));

    return Scaffold(
      backgroundColor: AppColors.adminDarkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.adminDarkSurface,
        elevation: 0,
        foregroundColor: AppColors.darkOnSurface,
        title: Text(driver.name,
            style: const TextStyle(
                color: AppColors.darkOnSurface, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(driverOrdersProvider(driver.id));
              ref.invalidate(driverLocationProvider(driver.id));
            },
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.darkOnSurfaceVariant),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ordersAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.brandGreenPrimary)),
        error: (e, _) => Center(
          child: Text('Could not load: $e',
              style: const TextStyle(color: AppColors.darkOnSurface)),
        ),
        data: (orders) {
          final now = DateTime.now();
          bool isToday(DateTime? d) =>
              d != null && d.year == now.year && d.month == now.month && d.day == now.day;

          final active = orders.where((o) => o.isActive).toList();
          final delivered = orders.where((o) => o.isDelivered).toList();
          final deliveredToday =
              delivered.where((o) => isToday(o.deliveredAt)).toList();
          final earnedToday = deliveredToday.fold<int>(0, (s, o) => s + o.totalCents);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Current status + location
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _StatusDot(active: active.isNotEmpty),
                        const SizedBox(width: 8),
                        Text(
                          active.isEmpty
                              ? 'Not currently delivering'
                              : 'Currently delivering (${active.length} active)',
                          style: const TextStyle(
                              color: AppColors.darkOnSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 15),
                        ),
                      ],
                    ),
                    if (driver.phone.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('📞 ${driver.phone}',
                          style: const TextStyle(
                              color: AppColors.darkOnSurfaceVariant)),
                    ],
                    if (active.any((o) => o.status == 'out_for_delivery'))
                      _LocationRow(driverId: driver.id),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Today's stats
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Delivered today',
                      value: '${deliveredToday.length}',
                      icon: Icons.check_circle_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: "Today's value",
                      value: CurrencyFormatter.format(earnedToday),
                      icon: Icons.payments_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Total delivered',
                      value: '${delivered.length}',
                      icon: Icons.local_shipping_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (active.isNotEmpty) ...[
                const _SectionTitle('Active delivery'),
                const SizedBox(height: 8),
                for (final o in active) _OrderTile(order: o),
                const SizedBox(height: 20),
              ],

              const _SectionTitle('Delivered orders'),
              const SizedBox(height: 8),
              if (delivered.isEmpty)
                const Text('No deliveries yet.',
                    style: TextStyle(color: AppColors.darkOnSurfaceVariant))
              else
                for (final o in delivered) _OrderTile(order: o),
            ],
          );
        },
      ),
    );
  }
}

class _LocationRow extends ConsumerWidget {
  const _LocationRow({required this.driverId});
  final String driverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locAsync = ref.watch(driverLocationProvider(driverId));
    return locAsync.maybeWhen(
      data: (loc) {
        if (loc == null) {
          return const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Live location not reported yet.',
                style: TextStyle(color: AppColors.darkOnSurfaceVariant, fontSize: 12)),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              const Icon(Icons.my_location_rounded,
                  size: 16, color: AppColors.brandGreenPrimary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Location: ${loc.lat.toStringAsFixed(5)}, ${loc.lng.toStringAsFixed(5)}',
                  style: const TextStyle(color: AppColors.darkOnSurface, fontSize: 13),
                ),
              ),
              TextButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(
                      'https://www.google.com/maps?q=${loc.lat},${loc.lng}'),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.map_rounded, size: 16),
                label: const Text('Open map'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.brandGreenPrimary),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});
  final DriverDelivery order;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.adminDarkSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.darkOutline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#${order.ref}',
                    style: const TextStyle(
                        color: AppColors.darkOnSurface,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace')),
                if (order.deliveryAddress.isNotEmpty)
                  Text(order.deliveryAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.darkOnSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
          Text(CurrencyFormatter.format(order.totalCents),
              style: const TextStyle(
                  color: AppColors.darkOnSurface, fontWeight: FontWeight.w700)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (order.isDelivered
                      ? AppColors.brandGreenPrimary
                      : AppColors.brandGold)
                  .withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              order.status.replaceAll('_', ' '),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: order.isDelivered
                    ? AppColors.brandGreenPrimary
                    : AppColors.brandGold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.adminDarkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkOutline),
        ),
        child: child,
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.brandGreenPrimary, size: 20),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    color: AppColors.darkOnSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 20)),
            Text(label,
                style: const TextStyle(
                    color: AppColors.darkOnSurfaceVariant, fontSize: 12)),
          ],
        ),
      );
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.active});
  final bool active;
  @override
  Widget build(BuildContext context) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? AppColors.brandGreenPrimary : AppColors.darkOnSurfaceVariant,
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: AppColors.darkOnSurface,
          fontWeight: FontWeight.w700,
          fontSize: 15));
}
