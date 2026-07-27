import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

import '../../auth/providers/auth_provider.dart';

/// Customer profile: personal details, shop details, and — importantly — the
/// shop's approval status (the person is approved on sign-up; only the shop
/// waits on admin approval).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final shopAsync = ref.watch(currentShopProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppColors.brandGreenPrimary,
        foregroundColor: AppColors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentUserProvider);
          ref.invalidate(currentShopProvider);
          await Future.wait([
            ref.read(currentUserProvider.future),
            ref.read(currentShopProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          children: [
            userAsync.when(
              data: (user) => _UserHeader(user: user),
              loading: () => const _LoadingCard(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: AppSpacing.x3l),

            Text(
              'MY SHOP',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.lightOnSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            shopAsync.when(
              data: (shop) =>
                  shop == null ? const _NoShopCard() : _ShopCard(shop: shop),
              loading: () => const _LoadingCard(),
              error: (_, __) => const _NoShopCard(),
            ),

            const SizedBox(height: AppSpacing.x4l),

            SpazaButton(
              label: 'Sign Out',
              variant: SpazaButtonVariant.outline,
              onPressed: () async {
                await signOut(ref);
                if (context.mounted) context.go(RouteConstants.welcome);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.user});
  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final name = (user?.displayName.isNotEmpty ?? false)
        ? user!.displayName
        : 'SpazaLink Member';
    final initials = name.trim().isNotEmpty
        ? name.trim().split(RegExp(r'\s+')).map((w) => w[0]).take(2).join()
        : '?';

    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.brandGreenSurface,
          child: Text(
            initials.toUpperCase(),
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.brandGreenDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTypography.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              if (user?.email != null && user!.email!.isNotEmpty)
                _IconLine(icon: Icons.email_outlined, text: user!.email!),
              if (user?.phoneNumber.isNotEmpty ?? false)
                _IconLine(
                  icon: Icons.phone_android_outlined,
                  text: user!.phoneNumber,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.lightOnSurfaceVariant),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.lightOnSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.shop});
  final ShopModel shop;

  @override
  Widget build(BuildContext context) {
    final status = _statusStyle(shop.status);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.lightSurfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.store_rounded,
                  color: AppColors.brandGreenPrimary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(shop.shopName, style: AppTypography.titleMedium),
              ),
              _StatusBadge(style: status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ShopRow(icon: Icons.location_on_outlined, text: shop.physicalAddress),
          if (shop.city.isNotEmpty || shop.province.isNotEmpty)
            _ShopRow(
              icon: Icons.map_outlined,
              text: [shop.city, shop.province]
                  .where((s) => s.isNotEmpty)
                  .join(', '),
            ),

          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: status.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                Icon(status.icon, size: 18, color: status.foreground),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    status.message,
                    style: AppTypography.bodySmall.copyWith(
                      color: status.foreground,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopRow extends StatelessWidget {
  const _ShopRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.lightOnSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.lightOnSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.style});
  final _StatusStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: style.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        style.label,
        style: AppTypography.labelSmall.copyWith(
          color: style.foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NoShopCard extends StatelessWidget {
  const _NoShopCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Text(
        'You have not registered a shop yet.',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.lightOnSurfaceVariant,
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

// ── Status styling ──────────────────────────────────────────────────────────────

class _StatusStyle {
  const _StatusStyle({
    required this.label,
    required this.message,
    required this.foreground,
    required this.surface,
    required this.icon,
  });
  final String label;
  final String message;
  final Color foreground;
  final Color surface;
  final IconData icon;
}

_StatusStyle _statusStyle(String status) {
  switch (status) {
    case AppConstants.shopStatusApproved:
      return const _StatusStyle(
        label: 'APPROVED',
        message: 'Your shop is approved. You can place wholesale orders.',
        foreground: AppColors.success,
        surface: AppColors.successLight,
        icon: Icons.check_circle_rounded,
      );
    case AppConstants.shopStatusRejected:
      return const _StatusStyle(
        label: 'NOT APPROVED',
        message:
            'Your shop registration was not approved. Please contact support.',
        foreground: AppColors.error,
        surface: AppColors.errorLight,
        icon: Icons.cancel_rounded,
      );
    case AppConstants.shopStatusSuspended:
      return const _StatusStyle(
        label: 'SUSPENDED',
        message: 'Your shop has been suspended. Please contact support.',
        foreground: AppColors.error,
        surface: AppColors.errorLight,
        icon: Icons.block_rounded,
      );
    case AppConstants.shopStatusPending:
    default:
      return const _StatusStyle(
        label: 'PENDING',
        message:
            'Your shop is awaiting admin approval. You can browse now — '
            'ordering unlocks once your shop is approved.',
        foreground: AppColors.warning,
        surface: AppColors.warningLight,
        icon: Icons.hourglass_top_rounded,
      );
  }
}
