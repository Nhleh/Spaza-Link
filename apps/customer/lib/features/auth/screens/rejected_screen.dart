import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';

class RejectedScreen extends ConsumerWidget {
  const RejectedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shop = ref.watch(currentShopProvider).valueOrNull;
    final isSuspended = shop?.status == AppConstants.shopStatusSuspended;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuspended
                      ? Icons.pause_circle_outline_rounded
                      : Icons.cancel_outlined,
                  size: 48,
                  color: AppColors.error,
                ),
              ),

              const SizedBox(height: AppSpacing.x3l),

              Text(
                isSuspended ? 'Account Suspended' : 'Application Not Approved',
                style: AppTypography.headlineMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.md),

              if (shop?.shopName != null) ...[
                Text(
                  shop!.shopName,
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.lightOnSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              if (shop?.rejectionReason != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reason',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        shop!.rejectionReason!,
                        style: AppTypography.bodyMedium.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ] else ...[
                Text(
                  isSuspended
                      ? 'Your account has been suspended. Please contact our support team for assistance.'
                      : 'Unfortunately your shop registration did not meet our requirements. Please contact support to learn more.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.lightOnSurfaceVariant,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.x3l),
              ],

              SpazaButton(
                label: 'WhatsApp Support',
                leadingIcon: Icons.chat_rounded,
                onPressed: () => _openWhatsApp(context, shop?.shopName),
                variant: SpazaButtonVariant.primary,
              ),

              const SizedBox(height: AppSpacing.md),

              SpazaButton(
                label: 'Sign Out',
                onPressed: () => signOut(ref),
                variant: SpazaButtonVariant.text,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openWhatsApp(BuildContext context, String? shopName) async {
    final message = Uri.encodeComponent(
      'Hi SpazaLink, I need help with my shop registration'
      '${shopName != null ? ' for $shopName' : ''}.',
    );
    final url = Uri.parse(
      'https://wa.me/${AppConstants.supportWhatsAppNumber.replaceAll('+', '')}?text=$message',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) context.showErrorSnack('Could not open WhatsApp.');
    }
  }
}
