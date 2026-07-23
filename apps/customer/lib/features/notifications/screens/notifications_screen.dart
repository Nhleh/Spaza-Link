import 'package:flutter/material.dart';
import 'package:spazalink_core/core.dart';

/// Notifications screen — placeholder until Phase 9 wires up FCM message storage.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.brandGreenPrimary,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x5l),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.brandGreenSurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 44,
                  color: AppColors.brandGreenPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.x3l),
              Text(
                'No notifications',
                style: AppTypography.headlineSmall
                    .copyWith(color: AppColors.lightOnSurface),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Order updates and promotions will appear here.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.lightOnSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
