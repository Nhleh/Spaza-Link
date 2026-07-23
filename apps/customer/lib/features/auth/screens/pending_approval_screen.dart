import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shop = ref.watch(currentShopProvider).valueOrNull;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.brandGold.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  size: 48,
                  color: AppColors.brandGold,
                ),
              ),

              const SizedBox(height: AppSpacing.x3l),

              Text(
                'Application Under Review',
                style: AppTypography.headlineMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.md),

              if (shop != null) ...[
                Text(
                  shop.shopName,
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.brandGreenPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              Text(
                'We are reviewing your shop registration.\n'
                'You will receive an SMS notification within 24–48 hours.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.lightOnSurfaceVariant,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.x4l),

              // What happens next
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.brandGreenSurface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What happens next',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.brandGreenDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _Step(
                      number: '1',
                      text: 'Our team reviews your shop details and documents.',
                    ),
                    _Step(
                      number: '2',
                      text: 'You receive an SMS once your shop is approved.',
                    ),
                    _Step(
                      number: '3',
                      text: 'Start placing wholesale orders at the best prices!',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.x3l),

              SpazaButton(
                label: 'WhatsApp Support',
                leadingIcon: Icons.chat_rounded,
                onPressed: () => _openWhatsApp(context),
                variant: SpazaButtonVariant.secondary,
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

  Future<void> _openWhatsApp(BuildContext context) async {
    final message = Uri.encodeComponent(
      'Hi SpazaLink, I need help with my shop registration.',
    );
    final url = Uri.parse(
      'https://wa.me/${AppConstants.supportWhatsAppNumber.replaceAll('+', '')}?text=$message',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) context.showErrorSnack('Could not open WhatsApp.');
    }
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});
  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.brandGreenPrimary,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.brandGreenDark,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
