import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'spaza_button.dart';

/// Enum of pre-defined empty state scenarios.
enum EmptyStateType {
  emptyCart,
  noOrders,
  noProducts,
  noNotifications,
  noInternet,
  pendingApproval,
  searchEmpty,
  noDeliveries,
  error,
}

/// Full-screen or inline empty state widget.
///
/// Shows a contextual icon, title, message, and optional CTA button.
/// Illustrations will be replaced with official assets in Phase 5.
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.type,
    this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final EmptyStateType type;
  final String? title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final config = _configFor(type);
    final effectiveTitle = title ?? config.title;
    final effectiveMessage = message ?? config.message;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.x4l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 64 : 96,
              height: compact ? 64 : 96,
              decoration: BoxDecoration(
                color: config.iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                config.icon,
                size: compact ? 32 : 48,
                color: config.iconColor,
              ),
            ),
            SizedBox(height: compact ? AppSpacing.md : AppSpacing.xxl),
            Text(
              effectiveTitle,
              style: (compact
                      ? AppTypography.titleSmall
                      : AppTypography.headlineSmall)
                  .copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
            Text(
              effectiveMessage,
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: compact ? AppSpacing.lg : AppSpacing.x3l),
              SpazaButton(
                label: actionLabel!,
                onPressed: onAction,
                isFullWidth: !compact,
              ),
            ],
          ],
        ),
      ),
    );
  }

  _EmptyStateConfig _configFor(EmptyStateType type) => switch (type) {
        EmptyStateType.emptyCart => const _EmptyStateConfig(
            icon: Icons.shopping_cart_outlined,
            iconColor: AppColors.brandGreenPrimary,
            iconBg: AppColors.brandGreenSurface,
            title: 'Your cart is empty',
            message: 'Browse our catalogue and add products to your cart.',
          ),
        EmptyStateType.noOrders => const _EmptyStateConfig(
            icon: Icons.receipt_long_outlined,
            iconColor: AppColors.brandGreenPrimary,
            iconBg: AppColors.brandGreenSurface,
            title: 'No orders yet',
            message: 'Your order history will appear here once you place your first order.',
          ),
        EmptyStateType.noProducts => const _EmptyStateConfig(
            icon: Icons.inventory_2_outlined,
            iconColor: AppColors.brandGold,
            iconBg: AppColors.brandGoldSurface,
            title: 'No products found',
            message: 'Try adjusting your search or filter to find what you\'re looking for.',
          ),
        EmptyStateType.noNotifications => const _EmptyStateConfig(
            icon: Icons.notifications_none_rounded,
            iconColor: AppColors.brandGreenPrimary,
            iconBg: AppColors.brandGreenSurface,
            title: 'No notifications',
            message: 'You\'re all caught up! Order updates will appear here.',
          ),
        EmptyStateType.noInternet => const _EmptyStateConfig(
            icon: Icons.wifi_off_rounded,
            iconColor: AppColors.warning,
            iconBg: AppColors.warningLight,
            title: 'No internet connection',
            message:
                'You\'re offline. You can still browse products and add items to your cart. Your orders will sync when you\'re back online.',
          ),
        EmptyStateType.pendingApproval => const _EmptyStateConfig(
            icon: Icons.hourglass_empty_rounded,
            iconColor: AppColors.brandGold,
            iconBg: AppColors.brandGoldSurface,
            title: 'Approval pending',
            message:
                'Your shop is being reviewed. You\'ll receive a notification as soon as it\'s approved — usually within 24 hours.',
          ),
        EmptyStateType.searchEmpty => const _EmptyStateConfig(
            icon: Icons.search_off_rounded,
            iconColor: AppColors.lightOnSurfaceVariant,
            iconBg: AppColors.lightSurfaceVariant,
            title: 'No results',
            message: 'No products match your search. Try different keywords.',
          ),
        EmptyStateType.noDeliveries => const _EmptyStateConfig(
            icon: Icons.local_shipping_outlined,
            iconColor: AppColors.brandGreenPrimary,
            iconBg: AppColors.brandGreenSurface,
            title: 'No deliveries',
            message: 'You have no deliveries assigned at the moment.',
          ),
        EmptyStateType.error => const _EmptyStateConfig(
            icon: Icons.error_outline_rounded,
            iconColor: AppColors.error,
            iconBg: AppColors.errorLight,
            title: 'Something went wrong',
            message: 'An unexpected error occurred. Please try again.',
          ),
      };
}

class _EmptyStateConfig {
  const _EmptyStateConfig({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String message;
}
