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
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full shop background, shown uncropped. `contain` guarantees the
          // entire photo is visible exactly as supplied — the dark backdrop
          // fills any thin letterbox area (the image ratio is near-identical to
          // a phone screen, so bars are minimal).
          Image.asset(
            'assets/images/welcome.png',
            fit: BoxFit.contain,
            alignment: Alignment.center,
          ),
          // Subtle scrim — clear at the top, darker toward the bottom — so the
          // buttons and help text stay readable over the photo.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00000000),
                  Color(0x40000000),
                  Color(0xA6000000),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Existing foreground UI (unchanged buttons + WhatsApp help). The
          // app's drawn logo/tagline are removed here because the shop sign and
          // slogan already appear in the background photo.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Column(
                children: [
                  const Spacer(flex: 6),

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
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
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
        ],
      ),
    );
  }

}
