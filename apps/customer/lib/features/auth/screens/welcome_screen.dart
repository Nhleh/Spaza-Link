import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

/// Landing screen shown to signed-out users.
///
/// Offers two paths: sign in to an existing account, or register a new shop.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 3),

              // Brand wordmark
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(children: [
                  TextSpan(
                    text: 'Spaza',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandGreenDark,
                      letterSpacing: -1.5,
                    ),
                  ),
                  TextSpan(
                    text: 'Link',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandGold,
                      letterSpacing: -1.5,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppConstants.appTagline,
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.lightOnSurfaceVariant,
                ),
              ),

              const Spacer(flex: 4),

              // Primary action — Login
              SpazaButton(
                label: 'Login',
                onPressed: () => context.go(RouteConstants.login),
                variant: SpazaButtonVariant.primary,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Secondary action — Register your shop
              SpazaButton(
                label: 'Register your shop',
                onPressed: () => context.go(RouteConstants.register),
                variant: SpazaButtonVariant.outline,
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
