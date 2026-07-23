import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Variants available for [SpazaButton].
enum SpazaButtonVariant { primary, secondary, outline, text, danger }

/// SpazaLink's primary interactive button.
///
/// Supports full-width and compact sizes, loading state, icon, and all four
/// visual variants matching the official design language.
class SpazaButton extends StatelessWidget {
  const SpazaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = SpazaButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.leadingIcon,
    this.trailingIcon,
    this.height = AppSpacing.buttonHeight,
  });

  final String label;
  final VoidCallback? onPressed;
  final SpazaButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == SpazaButtonVariant.outline ||
                        variant == SpazaButtonVariant.text
                    ? cs.primary
                    : cs.onPrimary,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: AppSpacing.iconMd),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label, style: AppTypography.labelLarge.copyWith(fontSize: 15)),
              if (trailingIcon != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(trailingIcon, size: AppSpacing.iconMd),
              ],
            ],
          );

    final effectiveCallback = isLoading ? null : onPressed;

    Widget button = switch (variant) {
      SpazaButtonVariant.primary => ElevatedButton(
          onPressed: effectiveCallback,
          child: child,
        ),
      SpazaButtonVariant.secondary => ElevatedButton(
          onPressed: effectiveCallback,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandGold,
            foregroundColor: AppColors.brandGreenDark,
          ),
          child: child,
        ),
      SpazaButtonVariant.outline => OutlinedButton(
          onPressed: effectiveCallback,
          child: child,
        ),
      SpazaButtonVariant.text => TextButton(
          onPressed: effectiveCallback,
          child: child,
        ),
      SpazaButtonVariant.danger => ElevatedButton(
          onPressed: effectiveCallback,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.white,
          ),
          child: child,
        ),
    };

    if (isFullWidth) {
      button = SizedBox(width: double.infinity, height: height, child: button);
    } else {
      button = SizedBox(height: height, child: button);
    }

    return button;
  }
}
