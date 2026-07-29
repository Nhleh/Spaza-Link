import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

import '../providers/shop_provider.dart';

/// Admin screen for reviewing shop registrations and approving/rejecting them.
class AdminShopsScreen extends ConsumerStatefulWidget {
  const AdminShopsScreen({super.key});

  @override
  ConsumerState<AdminShopsScreen> createState() => _AdminShopsScreenState();
}

class _AdminShopsScreenState extends ConsumerState<AdminShopsScreen> {
  // null = all; otherwise a shop status.
  String? _filter = AppConstants.shopStatusPending;

  static const _filters = <String, String?>{
    'Pending': AppConstants.shopStatusPending,
    'Approved': AppConstants.shopStatusApproved,
    'Rejected': AppConstants.shopStatusRejected,
    'All': null,
  };

  @override
  Widget build(BuildContext context) {
    ref.listen<ShopManagementState>(shopManagementProvider, (_, next) {
      if (next is ShopManagementSuccess) {
        _snack(next.message, AppColors.brandGreenPrimary);
        ref.read(shopManagementProvider.notifier).reset();
      } else if (next is ShopManagementError) {
        _snack(next.message, AppColors.error);
        ref.read(shopManagementProvider.notifier).reset();
      }
    });

    final shopsAsync = ref.watch(shopsByStatusProvider(_filter));

    return Scaffold(
      backgroundColor: AppColors.adminDarkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.adminDarkSurface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Shops',
          style: TextStyle(
            color: AppColors.darkOnSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            width: double.infinity,
            color: AppColors.adminDarkSurface,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Wrap(
              spacing: 8,
              children: _filters.entries.map((e) {
                final selected = _filter == e.value;
                return ChoiceChip(
                  label: Text(e.key),
                  selected: selected,
                  onSelected: (_) => setState(() => _filter = e.value),
                  labelStyle: TextStyle(
                    color: selected
                        ? AppColors.white
                        : AppColors.darkOnSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: AppColors.adminDarkSurfaceVariant,
                  selectedColor: AppColors.brandGreenPrimary,
                  showCheckmark: false,
                  side: BorderSide.none,
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: shopsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: AppColors.brandGreenPrimary),
              ),
              error: (e, _) => Center(
                child: Text('Failed to load shops:\n$e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.darkOnSurface)),
              ),
              data: (shops) {
                if (shops.isEmpty) {
                  return Center(
                    child: Text(
                      'No ${_filterLabel().toLowerCase()} shops.',
                      style: const TextStyle(
                          color: AppColors.darkOnSurfaceVariant),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: shops.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _ShopCard(shop: shops[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _filterLabel() =>
      _filters.entries.firstWhere((e) => e.value == _filter).key;

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }
}

class _ShopCard extends ConsumerWidget {
  const _ShopCard({required this.shop});
  final ShopModel shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(shopManagementProvider) is ShopManagementLoading;
    final status = _statusStyle(shop.status);

    return GestureDetector(
      onTap: () => context.go(
        '${RouteConstants.adminShops}/${shop.id}',
        extra: shop,
      ),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.adminDarkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.adminDarkOutline, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.store_rounded,
                  color: AppColors.brandGreenPrimary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  shop.shopName,
                  style: const TextStyle(
                    color: AppColors.darkOnSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: status.$2.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.$1,
                  style: TextStyle(
                    color: status.$2,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.darkOnSurfaceVariant),
            ],
          ),
          const SizedBox(height: 10),
          _row(Icons.person_outline_rounded, shop.ownerName),
          _row(Icons.location_on_outlined, shop.physicalAddress),
          _row(
            Icons.map_outlined,
            [shop.city, shop.province].where((s) => s.isNotEmpty).join(', '),
          ),
          if (shop.rejectionReason != null &&
              shop.rejectionReason!.isNotEmpty)
            _row(Icons.info_outline_rounded, 'Reason: ${shop.rejectionReason}'),

          if (shop.status == AppConstants.shopStatusPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
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
                      foregroundColor: AppColors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : () => _promptReject(context, ref),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
    );
  }

  Widget _row(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.darkOnSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.darkOnSurfaceVariant,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
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
                style: TextStyle(color: AppColors.darkOnSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Reject',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (reason != null && reason.isNotEmpty) {
      ref.read(shopManagementProvider.notifier).reject(shop.id, reason);
    }
  }

  /// (label, color) for a shop status.
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
