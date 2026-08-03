import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

import '../data/pools_repository.dart';
import '../providers/pools_provider.dart';

/// Bottom sheet to start a buying pool for [product]. Requires >= 50 units to
/// create; the creator also sets a target (where the pool auto-closes).
Future<void> showCreatePoolSheet(
  BuildContext context,
  WidgetRef ref,
  ProductModel product,
) async {
  var qty = kPoolMinCreateQty; // 50
  var target = 150; // default target = max-discount tier
  var busy = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        if (target < qty) target = qty;
        return Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl,
              AppSpacing.xl, AppSpacing.xl + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Start a buying pool',
                  style: AppTypography.titleLarge
                      .copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(product.name,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.lightOnSurfaceVariant)),
              const SizedBox(height: AppSpacing.lg),

              // Your pledge (min 50)
              _Row(
                label: 'Your units (min 50)',
                value: qty,
                onMinus: () =>
                    setState(() => qty = (qty - 5).clamp(kPoolMinCreateQty, 100000)),
                onPlus: () => setState(() => qty += 5),
              ),
              const SizedBox(height: AppSpacing.md),
              // Target to auto-close
              _Row(
                label: 'Target to close pool',
                value: target,
                onMinus: () =>
                    setState(() => target = (target - 10).clamp(qty, 100000)),
                onPlus: () => setState(() => target += 10),
              ),

              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                    color: AppColors.brandGreenSurfaceLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                child: Text(
                  'Others can join for 3 days. At 50 units everyone gets 5% off, '
                  '100 → 10%, 150 → 15% (max).',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.lightOnSurfaceVariant),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: busy
                      ? null
                      : () async {
                          setState(() => busy = true);
                          try {
                            final pool = await ref
                                .read(poolsRepositoryProvider)
                                .createPool(
                                    product: product,
                                    quantity: qty,
                                    targetQty: target);
                            ref.invalidate(openPoolsProvider);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              context.push('/pools/${pool.id}', extra: pool);
                            }
                          } catch (e) {
                            setState(() => busy = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                  content: Text('Could not start pool: $e')));
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreenPrimary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.white))
                      : Text('Start pool with $qty units'),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });
  final String label;
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData i, VoidCallback t) => InkWell(
          onTap: t,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: AppColors.brandGreenSurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            child: Icon(i, color: AppColors.brandGreenPrimary, size: 20),
          ),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTypography.bodyMedium
                .copyWith(fontWeight: FontWeight.w600)),
        Row(children: [
          btn(Icons.remove_rounded, onMinus),
          SizedBox(
            width: 64,
            child: Text('$value',
                textAlign: TextAlign.center,
                style: AppTypography.titleMedium
                    .copyWith(fontWeight: FontWeight.w800)),
          ),
          btn(Icons.add_rounded, onPlus),
        ]),
      ],
    );
  }
}
