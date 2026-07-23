import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

/// Admin Dashboard — login/entry screen (Phase 1 placeholder).
/// Phase 3 will implement actual Firebase Auth for the admin role.
class AdminSplashScreen extends StatefulWidget {
  const AdminSplashScreen({super.key});

  @override
  State<AdminSplashScreen> createState() => _AdminSplashScreenState();
}

class _AdminSplashScreenState extends State<AdminSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminDarkBackground,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.x4l),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  RichText(
                    text: const TextSpan(children: [
                      TextSpan(
                        text: 'Spaza',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                          letterSpacing: -1.5,
                        ),
                      ),
                      TextSpan(
                        text: 'Link',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandGold,
                          letterSpacing: -1.5,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'ADMIN DASHBOARD',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.brandGold,
                      letterSpacing: 0.14,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x4l),

                  // Login form placeholder
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    decoration: BoxDecoration(
                      color: AppColors.adminDarkSurface,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(color: AppColors.adminDarkOutline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Administrator Login',
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColors.darkOnSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Firebase Auth will be connected in Phase 2.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.darkOnSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        SpazaButton(
                          label: 'Enter Dashboard (Dev Mode)',
                          onPressed: () =>
                              context.go(RouteConstants.adminDashboard),
                          variant: SpazaButtonVariant.primary,
                        ),
                      ],
                    ),
                  ),

                  if (AppConfig.instance.isDevelopment) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandGold.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        'DEV BUILD · ${AppConfig.instance.firebaseProjectId}',
                        style: AppTypography.labelSmall
                            .copyWith(color: AppColors.brandGold),
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
