import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

import '../../categories/providers/category_provider.dart';
import '../providers/product_provider.dart';

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() =>
      _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    // Listen for delete success/error
    ref.listen<ProductManagementState>(productManagementProvider, (_, next) {
      if (next is ProductManagementSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.brandGreenPrimary,
          ),
        );
        ref.read(productManagementProvider.notifier).reset();
      } else if (next is ProductManagementError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(productManagementProvider.notifier).reset();
      }
    });

    final productsAsync = ref.watch(allProductsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.valueOrNull ?? [];
    final categoryMap = {for (final c in categories) c.id: c.name};

    return Scaffold(
      backgroundColor: AppColors.adminDarkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.adminDarkSurface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Products',
          style: TextStyle(
            color: AppColors.darkOnSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          FilledButton.icon(
            onPressed: () =>
                context.go(RouteConstants.adminProductCreate),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Add Product'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandGreenPrimary,
              foregroundColor: AppColors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppColors.adminDarkSurface,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: const TextStyle(
                  color: AppColors.darkOnSurface, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search by name or SKU…',
                hintStyle: const TextStyle(
                  color: AppColors.darkOnSurfaceVariant,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.darkOnSurfaceVariant,
                  size: 18,
                ),
                filled: true,
                fillColor: AppColors.adminDarkSurfaceVariant,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 1),

          // Table
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: AppColors.brandGreenPrimary),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Failed to load products',
                        style:
                            TextStyle(color: AppColors.darkOnSurface)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(allProductsProvider),
                      child: const Text('Retry',
                          style: TextStyle(
                              color: AppColors.brandGreenPrimary)),
                    ),
                  ],
                ),
              ),
              data: (products) {
                final q = _search.toLowerCase();
                final filtered = _search.isEmpty
                    ? products
                    : products
                        .where((p) =>
                            p.name.toLowerCase().contains(q) ||
                            p.sku.toLowerCase().contains(q))
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      _search.isNotEmpty
                          ? 'No products match "$_search"'
                          : 'No products yet. Tap Add Product.',
                      style: const TextStyle(
                          color: AppColors.darkOnSurfaceVariant),
                    ),
                  );
                }

                return DataTable2(
                  columnSpacing: 12,
                  horizontalMargin: 16,
                  headingRowColor: WidgetStateProperty.all(
                      AppColors.adminDarkSurfaceVariant),
                  dataRowColor: WidgetStateProperty.resolveWith((s) {
                    if (s.contains(WidgetState.hovered)) {
                      return AppColors.brandGreenPrimary
                          .withValues(alpha: 0.05);
                    }
                    return AppColors.adminDarkSurface;
                  }),
                  dividerThickness: 1,
                  border: TableBorder(
                    horizontalInside: BorderSide(
                      color: AppColors.adminDarkOutline,
                      width: 0.5,
                    ),
                  ),
                  headingTextStyle: const TextStyle(
                    color: AppColors.darkOnSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                  dataTextStyle: const TextStyle(
                    color: AppColors.darkOnSurface,
                    fontSize: 12,
                  ),
                  columns: const [
                    DataColumn2(
                        label: Text('NAME'), size: ColumnSize.L),
                    DataColumn2(
                        label: Text('CATEGORY'),
                        size: ColumnSize.M),
                    DataColumn2(
                        label: Text('SKU'), size: ColumnSize.M),
                    DataColumn2(
                        label: Text('PRICE'),
                        size: ColumnSize.S,
                        numeric: true),
                    DataColumn2(
                        label: Text('STOCK'),
                        size: ColumnSize.S,
                        numeric: true),
                    DataColumn2(
                        label: Text('STATUS'),
                        size: ColumnSize.S),
                    DataColumn2(
                        label: Text(''),
                        size: ColumnSize.S,
                        fixedWidth: 90),
                  ],
                  rows: filtered
                      .map((p) => _productRow(context, ref, p,
                          categoryMap[p.categoryId] ?? '—'))
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  DataRow2 _productRow(
    BuildContext context,
    WidgetRef ref,
    ProductModel p,
    String categoryName,
  ) {
    final actionState = ref.watch(productManagementProvider);
    final isDeleting = actionState is ProductManagementLoading;

    return DataRow2(
      onTap: () => context.go(
        '${RouteConstants.adminProducts}/${p.id}/edit',
        extra: p,
      ),
      cells: [
        DataCell(
          Row(
            children: [
              // Thumbnail
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.adminDarkSurfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                  image: p.imageUrls.isNotEmpty
                      ? DecorationImage(
                          image:
                              NetworkImage(p.imageUrls.first),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: p.imageUrls.isEmpty
                    ? const Icon(Icons.inventory_2_rounded,
                        size: 14,
                        color: AppColors.darkOnSurfaceVariant)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  p.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.darkOnSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        DataCell(Text(
          categoryName,
          overflow: TextOverflow.ellipsis,
          style:
              const TextStyle(color: AppColors.darkOnSurfaceVariant),
        )),
        DataCell(Text(
          p.sku.isNotEmpty ? p.sku : '—',
          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
        )),
        DataCell(Text(
          CurrencyFormatter.format(p.effectivePriceCents),
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.w600),
        )),
        DataCell(Text(
          '${p.stockQuantity}',
          textAlign: TextAlign.right,
          style: TextStyle(
            color: p.stockQuantity < 10
                ? AppColors.error
                : AppColors.darkOnSurface,
          ),
        )),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: p.isAvailable
                  ? AppColors.statusDelivered
                      .withValues(alpha: 0.12)
                  : AppColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              p.isAvailable ? 'Active' : 'Hidden',
              style: TextStyle(
                color: p.isAvailable
                    ? AppColors.statusDelivered
                    : AppColors.error,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_rounded,
                    size: 15,
                    color: AppColors.darkOnSurfaceVariant),
                tooltip: 'Edit',
                onPressed: () => context.go(
                  '${RouteConstants.adminProducts}/${p.id}/edit',
                  extra: p,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 15, color: AppColors.error),
                tooltip: 'Delete',
                onPressed: isDeleting
                    ? null
                    : () => _confirmDelete(context, ref, p),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, ProductModel p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.adminDarkSurface,
        title: const Text('Delete product?',
            style: TextStyle(color: AppColors.darkOnSurface)),
        content: Text(
          'This will permanently remove "${p.name}". This cannot be undone.',
          style: const TextStyle(
              color: AppColors.darkOnSurfaceVariant, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style:
                    TextStyle(color: AppColors.darkOnSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (ok == true) {
      ref.read(productManagementProvider.notifier).delete(p.id);
    }
  }
}
