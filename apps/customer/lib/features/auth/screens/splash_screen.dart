import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

/// SpazaLink Customer App — Splash Screen.
///
/// Shows brand identity for a fixed duration, then hands off to login.
/// GoRouter's redirect guard handles routing to the correct destination
/// based on auth + shop state. Phase 5 will add the logo asset.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleIn;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleIn = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();

    // After the minimum splash duration, navigate to the welcome screen.
    // GoRouter's auth redirect will immediately forward to the correct
    // destination (home, pendingApproval, etc.) based on auth state.
    Future.delayed(AppConstants.splashDuration, () {
      if (mounted) context.go(RouteConstants.welcome);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandGreenDark,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.brandGreenDark,
                  Color(0xFF0D2B13),
                ],
              ),
            ),
          ),

          // Phase 5: Replace background gradient with spaza shop photo + dark overlay.
          // Image.asset('assets/images/splash_background.jpg', fit: BoxFit.cover, ...)

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x5l,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Logo
                  FadeTransition(
                    opacity: _fadeIn,
                    child: ScaleTransition(
                      scale: _scaleIn,
                      child: _LogoWidget(),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.x3l),

                  // Tagline
                  FadeTransition(
                    opacity: _fadeIn,
                    child: Column(
                      children: [
                        Text(
                          'Stronger together.',
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.white.withValues(alpha: 0.9),
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Cheaper together.',
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.brandGold,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Environment label (dev only)
                  if (AppConfig.instance.isDevelopment)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandGold.withValues(alpha: 0.2),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                        border: Border.all(
                          color: AppColors.brandGold.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        'DEV BUILD',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.brandGold,
                          letterSpacing: 0.12,
                        ),
                      ),
                    ),

                  const SizedBox(height: AppSpacing.x3l),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder logo widget — replaced with official [Image.asset] in Phase 5.
class _LogoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Phase 5: Replace with Image.asset('assets/images/logo.png', height: 100)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Chain icon placeholder
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.brandGreenPrimary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.link_rounded,
                size: 40,
                color: AppColors.white,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Spaza',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                          letterSpacing: -1.0,
                          height: 1.1,
                        ),
                      ),
                      TextSpan(
                        text: 'Link',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandGold,
                          letterSpacing: -1.0,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
