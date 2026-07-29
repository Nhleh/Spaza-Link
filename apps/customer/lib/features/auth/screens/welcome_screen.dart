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
              const Spacer(flex: 3),

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
                AppConstants.appTagline,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.lightOnSurfaceVariant),
              ),

              const Spacer(flex: 3),

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

}
