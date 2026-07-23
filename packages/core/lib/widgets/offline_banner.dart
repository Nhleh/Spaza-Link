import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Visual sync state for the offline order chip widget.
enum OfflineSyncStatus { pendingSync, syncing, sent, failed }

extension OfflineSyncStatusX on OfflineSyncStatus {
  String get label => switch (this) {
        OfflineSyncStatus.pendingSync => 'Pending Sync',
        OfflineSyncStatus.syncing => 'Syncing…',
        OfflineSyncStatus.sent => 'Successfully Sent',
        OfflineSyncStatus.failed => 'Failed',
      };

  Color get colour => switch (this) {
        OfflineSyncStatus.pendingSync => AppColors.syncPending,
        OfflineSyncStatus.syncing => AppColors.syncSyncing,
        OfflineSyncStatus.sent => AppColors.syncSent,
        OfflineSyncStatus.failed => AppColors.syncFailed,
      };

  IconData get icon => switch (this) {
        OfflineSyncStatus.pendingSync => Icons.schedule_rounded,
        OfflineSyncStatus.syncing => Icons.sync_rounded,
        OfflineSyncStatus.sent => Icons.check_circle_rounded,
        OfflineSyncStatus.failed => Icons.error_rounded,
      };
}

/// Amber banner displayed when the device is offline.
///
/// Shown as a persistent strip at the top of screens (below the app bar)
/// whenever connectivity is unavailable.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.warning,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.white, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'You are offline. Your order will be sent automatically when your connection is restored.',
              style: AppTypography.labelSmall.copyWith(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip widget showing the sync status of a queued offline order.
class SyncStatusChip extends StatelessWidget {
  const SyncStatusChip({
    super.key,
    required this.status,
    this.onRetry,
  });

  final OfflineSyncStatus status;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: status.colour.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: status.colour.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == OfflineSyncStatus.syncing)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(status.colour),
              ),
            )
          else
            Icon(status.icon, size: 14, color: status.colour),
          const SizedBox(width: AppSpacing.xs),
          Text(
            status.label,
            style:
                AppTypography.labelSmall.copyWith(color: status.colour),
          ),
          if (status == OfflineSyncStatus.failed && onRetry != null) ...[
            const SizedBox(width: AppSpacing.xs),
            GestureDetector(
              onTap: onRetry,
              child: Text(
                '· Retry',
                style: AppTypography.labelSmall.copyWith(
                  color: status.colour,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
