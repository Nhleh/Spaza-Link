import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';

import '../data/supabase_product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return SupabaseProductRepository();
});

/// All available products in a category (real-time stream).
final categoryProductsProvider =
    StreamProvider.family<List<ProductModel>, String?>((ref, categoryId) {
  return ref
      .watch(productRepositoryProvider)
      .watchProducts(categoryId: categoryId);
});

/// Featured products for the home screen banner.
final featuredProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  return ref
      .watch(productRepositoryProvider)
      .watchProducts(featuredOnly: true);
});

final singleProductProvider =
    FutureProvider.family<ProductModel?, String>((ref, productId) {
  return ref.watch(productRepositoryProvider).getProduct(productId);
});

/// Search results — empty list while query is blank.
final productSearchProvider =
    FutureProvider.family<List<ProductModel>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  return ref.watch(productRepositoryProvider).searchProducts(query.trim());
});
