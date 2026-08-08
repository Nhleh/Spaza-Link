import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/delivery.dart';
import '../providers/delivery_provider.dart';
import 'complete_delivery_screen.dart';

class DeliveryDetailScreen extends ConsumerStatefulWidget {
  const DeliveryDetailScreen({super.key, required this.orderId, this.initial});

  final String orderId;
  final Delivery? initial;

  @override
  ConsumerState<DeliveryDetailScreen> createState() =>
      _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends ConsumerState<DeliveryDetailScreen> {
  bool _busy = false;

  Future<void> _navigate(String address) async {
    if (address.isEmpty) return;
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(address)}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _confirmPickup(Delivery d) async {
    setState(() => _busy = true);
    try {
      await ref.read(driverDeliveryRepositoryProvider).confirmPickup(d.orderId);
      ref.invalidate(deliveryDetailProvider(d.orderId));
      ref.invalidate(myDeliveriesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Could not confirm pickup: $e'),
            backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(deliveryDetailProvider(widget.orderId));
    final d = async.valueOrNull ?? widget.initial;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.brandGreenPrimary,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(d == null ? 'Delivery' : 'Order #${d.ref}',
            style: const TextStyle(
                color: AppColors.white, fontWeight: FontWeight.w700)),
      ),
      body: d == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brandGreenPrimary))
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // Current target (pickup or delivery)
                _TargetCard(
                  label: d.currentTargetLabel,
                  address: d.currentTargetAddress,
                  onNavigate: () => _navigate(d.currentTargetAddress),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Items
                _Card(
                  title: 'Items (${d.items.length})',
                  child: Column(
                    children: [
                      for (final it in d.items)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(it.name,
                                    style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.lightOnSurface)),
                              ),
                              Text('×${it.qty}',
                                  style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.lightOnSurfaceVariant)),
                              const SizedBox(width: 12),
                              Text(CurrencyFormatter.format(it.lineTotalCents),
                                  style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.lightOnSurface)),
                            ],
                          ),
                        ),
                      const Divider(color: AppColors.lightOutlineVariant),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total',
                              style: AppTypography.titleSmall
                                  .copyWith(fontWeight: FontWeight.w800)),
                          Text(CurrencyFormatter.format(d.totalCents),
                              style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.lightOnSurface)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          d.isCod
                              ? 'Payment: Cash on Delivery'
                              : 'Payment: ${d.paymentMethod}',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.lightOnSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x3l),

                // Action
                SizedBox(
                  height: AppSpacing.buttonHeight,
                  child: d.isAssigned
                      ? FilledButton.icon(
                          onPressed: _busy ? null : () => _confirmPickup(d),
                          icon: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppColors.white))
                              : const Icon(Icons.check_rounded),
                          label: const Text('Confirm pickup',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          style: FilledButton.styleFrom(
                              backgroundColor: AppColors.brandGreenPrimary,
                              foregroundColor: AppColors.white),
                        )
                      : FilledButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CompleteDeliveryScreen(delivery: d),
                            ),
                          ),
                          icon: const Icon(Icons.draw_rounded),
                          label: const Text('Complete delivery',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          style: FilledButton.styleFrom(
                              backgroundColor: AppColors.brandGreenPrimary,
                              foregroundColor: AppColors.white),
                        ),
                ),
                const SizedBox(height: AppSpacing.x3l),
              ],
            ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard(
      {required this.label, required this.address, required this.onNavigate});
  final String label;
  final String address;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(label.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                  color: AppColors.white.withValues(alpha: 0.85),
                  letterSpacing: 0.6)),
          const SizedBox(height: 4),
          Text(address.isEmpty ? 'Address not provided' : address,
              style: AppTypography.titleSmall.copyWith(
                  color: AppColors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: address.isEmpty ? null : onNavigate,
              icon: const Icon(Icons.navigation_rounded, size: 18),
              label: const Text('Navigate (Google Maps)'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.brandGreenDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.lightOutlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTypography.titleSmall
                  .copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
