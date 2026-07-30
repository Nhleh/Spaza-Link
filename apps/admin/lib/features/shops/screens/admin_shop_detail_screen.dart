import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/shop_provider.dart';

/// Owner profile (contact details + preferences) fetched for the detail view.
final _ownerProfileProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, ownerId) async {
  if (ownerId.isEmpty) return null;
  return Supabase.instance.client
      .from('profiles')
      .select()
      .eq('id', ownerId)
      .maybeSingle();
});

/// This shop's order history (newest first).
final _shopOrdersProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, shopId) async {
  final rows = await Supabase.instance.client
      .from('orders')
      .select('id,status,total_cents,created_at')
      .eq('shop_id', shopId)
      .order('created_at', ascending: false);
  return (rows as List).cast<Map<String, dynamic>>();
});

class AdminShopDetailScreen extends ConsumerWidget {
  const AdminShopDetailScreen({super.key, required this.shopId, this.shop});

  final String shopId;
  final ShopModel? shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fall back to the shops list if navigated without an extra (e.g. refresh).
    final resolved = shop ??
        ref
            .watch(shopsByStatusProvider(null))
            .valueOrNull
            ?.where((s) => s.id == shopId)
            .firstOrNull;

    ref.listen<ShopManagementState>(shopManagementProvider, (_, next) {
      if (next is ShopManagementSuccess) {
        _snack(context, next.message, AppColors.brandGreenPrimary);
        ref.read(shopManagementProvider.notifier).reset();
      } else if (next is ShopManagementError) {
        _snack(context, next.message, AppColors.error);
        ref.read(shopManagementProvider.notifier).reset();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.adminDarkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.adminDarkSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.darkOnSurface),
          onPressed: () => context.go(RouteConstants.adminShops),
        ),
        title: Text(resolved?.shopName ?? 'Shop',
            style: const TextStyle(
                color: AppColors.darkOnSurface, fontWeight: FontWeight.w700)),
      ),
      body: resolved == null
          ? const Center(
              child: Text('Shop not found.',
                  style: TextStyle(color: AppColors.darkOnSurfaceVariant)))
          : _Body(shop: resolved),
    );
  }

  static void _snack(BuildContext c, String m, Color color) =>
      ScaffoldMessenger.of(c)
          .showSnackBar(SnackBar(content: Text(m), backgroundColor: color));
}

class _Body extends ConsumerWidget {
  const _Body({required this.shop});
  final ShopModel shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owner = ref.watch(_ownerProfileProvider(shop.ownerId));
    final busy = ref.watch(shopManagementProvider) is ShopManagementLoading;
    final status = _statusStyle(shop.status);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Status + actions header
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.store_rounded,
                    color: AppColors.brandGreenPrimary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(shop.shopName,
                      style: const TextStyle(
                          color: AppColors.darkOnSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: status.$2.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(status.$1,
                      style: TextStyle(
                          color: status.$2,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                if (shop.status == AppConstants.shopStatusPending) ...[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: busy
                          ? null
                          : () => ref
                              .read(shopManagementProvider.notifier)
                              .approve(shop.id),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Approve'),
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brandGreenPrimary,
                          foregroundColor: AppColors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          busy ? null : () => _promptReject(context, ref),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error)),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.go(
                        '${RouteConstants.adminShops}/message/${shop.ownerId}'),
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Message owner'),
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.adminDarkSurfaceVariant,
                        foregroundColor: AppColors.darkOnSurface),
                  ),
                ),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _section('Shop', [
          _kv('Shop name', shop.shopName),
          _kv('Status', status.$1),
          _kv('Physical address', shop.physicalAddress),
          _kv('City', shop.city),
          _kv('Province', shop.province),
          if (shop.gpsLocation != null)
            _kv('GPS',
                '${shop.gpsLocation!.latitude}, ${shop.gpsLocation!.longitude}'),
          _kv('Registered', _fmt(shop.createdAt)),
          if (shop.approvedAt != null) _kv('Approved', _fmt(shop.approvedAt!)),
          if (shop.rejectionReason != null &&
              shop.rejectionReason!.isNotEmpty)
            _kv('Rejection reason', shop.rejectionReason!),
        ]),
        const SizedBox(height: 16),

        owner.when(
          loading: () => _section('Owner', [_kv('', 'Loading…')]),
          error: (e, _) => _section('Owner', [_kv('Error', '$e')]),
          data: (p) => _section('Owner', [
            _kv('Name', (p?['display_name'] as String?) ?? shop.ownerName),
            _kv('Email', (p?['email'] as String?) ?? '—'),
            _kv('Phone', (p?['phone_number'] as String?) ?? '—'),
            _kv('Preferred payment',
                _paymentLabel((p?['preferences'] as Map?)?['payment_method'])),
          ]),
        ),
        const SizedBox(height: 16),

        // Order history for this shop
        _OrderHistory(shopId: shop.id),
      ],
    );
  }

  String _paymentLabel(dynamic v) {
    switch (v) {
      case 'eft':
        return 'EFT / Bank Transfer';
      case 'cod':
        return 'Cash on Delivery';
      default:
        return '—';
    }
  }

  Future<void> _promptReject(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.adminDarkSurface,
        title: const Text('Reject shop?',
            style: TextStyle(color: AppColors.darkOnSurface)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.darkOnSurface),
          decoration: const InputDecoration(
            hintText: 'Reason (shown to the shop owner)',
            hintStyle: TextStyle(color: AppColors.darkOnSurfaceVariant),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.darkOnSurfaceVariant))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Reject',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (reason != null && reason.isNotEmpty) {
      ref.read(shopManagementProvider.notifier).reject(shop.id, reason);
    }
  }

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.adminDarkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.adminDarkOutline, width: 0.5),
        ),
        child: child,
      );

  Widget _section(String title, List<Widget> rows) => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.toUpperCase(),
                style: const TextStyle(
                    color: AppColors.darkOnSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6)),
            const SizedBox(height: 12),
            ...rows,
          ],
        ),
      );

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 140,
            child: Text(k,
                style: const TextStyle(
                    color: AppColors.darkOnSurfaceVariant, fontSize: 12.5)),
          ),
          Expanded(
            child: Text(v.isEmpty ? '—' : v,
                style: const TextStyle(
                    color: AppColors.darkOnSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ]),
      );

  static String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  (String, Color) _statusStyle(String status) {
    switch (status) {
      case AppConstants.shopStatusApproved:
        return ('APPROVED', AppColors.statusDelivered);
      case AppConstants.shopStatusRejected:
        return ('REJECTED', AppColors.error);
      case AppConstants.shopStatusSuspended:
        return ('SUSPENDED', AppColors.error);
      default:
        return ('PENDING', AppColors.brandGold);
    }
  }
}

class _OrderHistory extends ConsumerWidget {
  const _OrderHistory({required this.shopId});
  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_shopOrdersProvider(shopId));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.adminDarkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.adminDarkOutline, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Expanded(
              child: Text('ORDER HISTORY',
                  style: TextStyle(
                      color: AppColors.darkOnSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6)),
            ),
            async.maybeWhen(
              data: (o) => Text('${o.length} order${o.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                      color: AppColors.darkOnSurfaceVariant, fontSize: 11.5)),
              orElse: () => const SizedBox.shrink(),
            ),
          ]),
          const SizedBox(height: 12),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.brandGreenPrimary)),
            ),
            error: (e, _) => Text('Could not load orders: $e',
                style: const TextStyle(color: AppColors.error, fontSize: 12.5)),
            data: (orders) {
              if (orders.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No orders yet.',
                      style: TextStyle(color: AppColors.darkOnSurfaceVariant)),
                );
              }
              return Column(
                children: [for (final o in orders) _row(context, o)],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, Map<String, dynamic> o) {
    final id = (o['id'] as String?) ?? '';
    final ref = id.isEmpty ? '—' : id.split('-').first.toUpperCase();
    final status = (o['status'] as String?) ?? 'pending';
    final total = (o['total_cents'] as num?)?.toInt() ?? 0;
    final created =
        DateTime.tryParse(o['created_at']?.toString() ?? '')?.toLocal();
    final color = _statusColor(status);
    return InkWell(
      onTap: id.isEmpty
          ? null
          : () => context.go('${RouteConstants.adminOrders}/$id'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#$ref',
                      style: const TextStyle(
                          color: AppColors.darkOnSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  if (created != null) ...[
                    const SizedBox(height: 2),
                    Text(_fmt(created),
                        style: const TextStyle(
                            color: AppColors.darkOnSurfaceVariant,
                            fontSize: 11.5)),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(status.toUpperCase(),
                  style: TextStyle(
                      color: color,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Text(CurrencyFormatter.format(total),
                style: const TextStyle(
                    color: AppColors.darkOnSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  static Color _statusColor(String s) {
    switch (s) {
      case 'delivered':
        return AppColors.statusDelivered;
      case 'cancelled':
        return AppColors.error;
      case 'pending':
        return AppColors.brandGold;
      default:
        return AppColors.brandGreenPrimary;
    }
  }

  static String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
