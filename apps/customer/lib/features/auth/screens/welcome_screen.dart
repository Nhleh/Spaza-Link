import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';
import 'package:url_launcher/url_launcher.dart';

/// Landing screen shown to signed-out users — matches the onboarding mockup:
/// logo + tagline, a delivery/shop hero, welcome copy, Login/Register, and a
/// WhatsApp help link.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _whatsApp() async {
    final uri = Uri.parse('https://wa.me/27720000000');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),

              // Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_rounded,
                      color: AppColors.brandGreenPrimary, size: 26),
                  const SizedBox(width: 8),
                  RichText(
                    text: const TextSpan(children: [
                      TextSpan(
                        text: 'Spaza',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandGreenDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: 'Link',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandGold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Bulk more. Save more. We deliver.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.lightOnSurfaceVariant),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Hero illustration (truck + spaza shop)
              const _HeroScene(),

              const SizedBox(height: AppSpacing.x3l),

              Text(
                'Welcome to SpazaLink',
                textAlign: TextAlign.center,
                style: AppTypography.headlineSmall
                    .copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'The smart way for spaza shops to order in bulk and save more.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.lightOnSurfaceVariant, height: 1.4),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Carousel dots (decorative)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _dot(true),
                  _dot(false),
                  _dot(false),
                ],
              ),

              const Spacer(),

              SpazaButton(
                label: 'Login',
                onPressed: () => context.go(RouteConstants.login),
                variant: SpazaButtonVariant.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              SpazaButton(
                label: 'Register',
                onPressed: () => context.go(RouteConstants.register),
                variant: SpazaButtonVariant.outline,
              ),

              const SizedBox(height: AppSpacing.lg),

              // WhatsApp help
              InkWell(
                onTap: _whatsApp,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Need help? Contact us on WhatsApp',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.lightOnSurfaceVariant),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFF25D366), // WhatsApp green
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chat_rounded,
                            color: AppColors.white, size: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(bool active) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: active ? 22 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: active
              ? AppColors.brandGreenPrimary
              : AppColors.lightOutlineVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
      );
}

/// Icon-based hero: a delivery truck arriving at a spaza shop, on a soft card.
/// (Swap for an illustration asset later for a pixel-perfect match.)
class _HeroScene extends StatelessWidget {
  const _HeroScene();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.brandGreenSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Stack(
        children: [
          // Shop sign
          Positioned(
            top: 22,
            right: 28,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.brandGreenPrimary),
              ),
              child: Text('SPAZA SHOP',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.brandGreenDark,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  )),
            ),
          ),
          // Shop building
          const Positioned(
            bottom: 26,
            right: 30,
            child: Icon(Icons.storefront_rounded,
                color: AppColors.brandGreenPrimary, size: 96),
          ),
          // Delivery truck
          const Positioned(
            bottom: 30,
            left: 24,
            child: Icon(Icons.local_shipping_rounded,
                color: AppColors.brandGold, size: 80),
          ),
          // Ground line
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Container(
              height: 2,
              color: AppColors.brandGreenPrimary.withValues(alpha: 0.25),
            ),
          ),
        ],
      ),
    );
  }
}
