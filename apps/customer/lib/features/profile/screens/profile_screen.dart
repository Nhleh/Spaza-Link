import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

import '../../auth/providers/auth_provider.dart';

/// Customer profile — matches the mockup: shop header with photo + address +
/// Edit, then a list of settings rows, then Logout. The shop's approval status
/// is surfaced as a small badge on the header.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final shopAsync = ref.watch(currentShopProvider);
    final shop = shopAsync.valueOrNull;
    final user = userAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppColors.brandGreenPrimary,
        foregroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        color: AppColors.brandGreenPrimary,
        onRefresh: () async {
          ref.invalidate(currentUserProvider);
          ref.invalidate(currentShopProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.x4l,
          ),
          children: [
            _ProfileHeader(shop: shop, user: user),
            const SizedBox(height: AppSpacing.lg),

            _SettingsGroup(
              rows: [
                _RowData(
                  icon: Icons.storefront_outlined,
                  label: 'Shop Information',
                  onTap: () => context.push('${RouteConstants.profile}/shop-info'),
                ),
                _RowData(
                  icon: Icons.location_on_outlined,
                  label: 'Delivery Addresses',
                  onTap: () =>
                      context.push('${RouteConstants.profile}/delivery-addresses'),
                ),
                _RowData(
                  icon: Icons.credit_card_outlined,
                  label: 'Payment Methods',
                  onTap: () =>
                      context.push('${RouteConstants.profile}/payment-methods'),
                ),
                _RowData(
                  icon: Icons.lock_outline_rounded,
                  label: 'Change Password',
                  onTap: () =>
                      context.push('${RouteConstants.profile}/change-password'),
                ),
                _RowData(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notification Settings',
                  onTap: () =>
                      context.push('${RouteConstants.profile}/notifications'),
                ),
                _RowData(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  onTap: () => context.push('${RouteConstants.profile}/support'),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Logout
            _SettingsGroup(
              rows: [
                _RowData(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  danger: true,
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Log out?'),
                        content: const Text('You can sign back in any time.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Logout',
                                style: TextStyle(color: AppColors.error)),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                    await signOut(ref);
                    // Route through the branded splash, which then forwards to
                    // the Welcome screen (Login + Register). Splash has a solid
                    // background, so there's no black flash on the way out.
                    if (context.mounted) context.go(RouteConstants.splash);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({this.shop, this.user});
  final ShopModel? shop;
  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final shopName = shop?.shopName ?? (user?.displayName ?? 'Your Shop');
    final address = [
      shop?.physicalAddress ?? '',
      [shop?.city ?? '', shop?.province ?? '']
          .where((s) => s.isNotEmpty)
          .join(', '),
    ].where((s) => s.isNotEmpty).join('\n');

    return Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShopAvatar(url: shop?.shopPhotoUrl),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            shopName,
                            style: AppTypography.titleMedium
                                .copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (shop != null) _StatusChip(status: shop!.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address.isEmpty ? 'No address on file' : address,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.lightOnSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.push('${RouteConstants.profile}/shop-info'),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brandGreenPrimary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopAvatar extends StatelessWidget {
  const _ShopAvatar({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    const size = 64.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: (url == null || url!.isEmpty)
          ? Container(
              width: size,
              height: size,
              color: AppColors.brandGreenSurface,
              child: const Icon(Icons.storefront_rounded,
                  color: AppColors.brandGreenPrimary, size: 30),
            )
          : CachedNetworkImage(
              imageUrl: url!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: size,
                height: size,
                color: AppColors.brandGreenSurface,
                child: const Icon(Icons.storefront_rounded,
                    color: AppColors.brandGreenPrimary, size: 30),
              ),
            ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    late final Color fg;
    late final Color bg;
    late final String label;
    switch (status) {
      case AppConstants.shopStatusApproved:
        fg = AppColors.success;
        bg = AppColors.successLight;
        label = 'Approved';
        break;
      case AppConstants.shopStatusRejected:
      case AppConstants.shopStatusSuspended:
        fg = AppColors.error;
        bg = AppColors.errorLight;
        label = 'Blocked';
        break;
      default:
        fg = AppColors.warning;
        bg = AppColors.warningLight;
        label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall
            .copyWith(color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ── Settings rows ─────────────────────────────────────────────────────────────

class _RowData {
  const _RowData({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.rows});
  final List<_RowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.lightOutlineVariant),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _SettingsRow(data: rows[i]),
            if (i != rows.length - 1)
              const Divider(height: 1, indent: 56, endIndent: 12),
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.data});
  final _RowData data;

  @override
  Widget build(BuildContext context) {
    final color =
        data.danger ? AppColors.error : AppColors.lightOnSurface;
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            Icon(data.icon,
                size: 22,
                color: data.danger
                    ? AppColors.error
                    : AppColors.brandGreenPrimary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                data.label,
                style: AppTypography.bodyLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (!data.danger)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.lightOnSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
