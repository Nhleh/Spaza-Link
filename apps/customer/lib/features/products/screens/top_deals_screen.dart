import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';

import '../providers/product_provider.dart';
import '../widgets/product_card.dart';

/// Full list of Top Deals (all products flagged as a Top Deal in admin).
class TopDealsScreen extends ConsumerWidget {
  const TopDealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(featuredProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Top Deals'),
        backgroundColor: AppColors.brandGreenPrimary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppColors.brandGreenPrimary,
        onRefresh: () async => ref.invalidate(featuredProductsProvider),
        child: async.when(
          loading: () => const Center(
              child:
                  CircularProgressIndicator(color: AppColors.brandGreenPrimary)),
          error: (e, _) => ListView(children: [
            const SizedBox(height: 120),
            Center(
                child: Text('Could not load Top Deals.\n$e',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.lightOnSurfaceVariant))),
          ]),
          data: (products) {
            if (products.isEmpty) {
              return const Center(
                child: EmptyStateWidget(
                    type: EmptyStateType.noProducts,
                    message: 'No Top Deals right now.'),
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.62,
              ),
              itemCount: products.length,
              itemBuilder: (_, i) => ProductCard(product: products[i]),
            );
          },
        ),
      ),
    );
  }
}
