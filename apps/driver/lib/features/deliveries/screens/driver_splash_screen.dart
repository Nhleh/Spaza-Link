import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

/// Driver App — animated splash screen.
///
/// Shows brand identity for a fixed duration, then hands off to driver login.
/// GoRouter's auth redirect handles forwarding to deliveries if already signed in.
class DriverSplashScreen extends StatefulWidget {
  const DriverSplashScreen({super.key});

  @override
  State<DriverSplashScreen> createState() => _DriverSplashScreenState();
}

class _DriverSplashScreenState extends State<DriverSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
    Future.delayed(AppConstants.splashDuration, () {
      if (mounted) context.go(RouteConstants.driverLogin);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandGreenDark,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) => FadeTransition(
              opacity: _fade,
              child: Transform.translate(
                offset: Offset(0, _slide.value),
                child: child,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4l),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Truck icon badge
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.brandGold,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusXl),
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: AppColors.brandGreenDark,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Brand wordmark
                  RichText(
                    text: const TextSpan(children: [
                      TextSpan(
                        text: 'Spaza',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                          letterSpacing: -1.0,
                        ),
                      ),
                      TextSpan(
                        text: 'Link',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandGold,
                          letterSpacing: -1.0,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'DRIVER',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.brandGold,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x3l),

                  if (AppConfig.instance.isDevelopment) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandGold.withValues(alpha: 0.20),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        'DEV BUILD · ${AppConfig.instance.firebaseProjectId}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.brandGold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
