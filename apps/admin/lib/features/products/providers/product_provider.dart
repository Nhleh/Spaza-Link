import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';

import '../data/supabase_product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return SupabaseProductRepository();
});

final allProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  return ref.watch(productRepositoryProvider).watchProducts();
});

final categoryProductsProvider =
    StreamProvider.family<List<ProductModel>, String>((ref, categoryId) {
  return ref
      .watch(productRepositoryProvider)
      .watchProducts(categoryId: categoryId);
});

// ── Admin product management notifier ────────────────────────────────────────

sealed class ProductManagementState {}

class ProductManagementIdle extends ProductManagementState {}

class ProductManagementLoading extends ProductManagementState {}

class ProductManagementSuccess extends ProductManagementState {
  ProductManagementSuccess(this.message);
  final String message;
}

class ProductManagementError extends ProductManagementState {
  ProductManagementError(this.message);
  final String message;
}

class ProductManagementNotifier extends Notifier<ProductManagementState> {
  @override
  ProductManagementState build() => ProductManagementIdle();

  ProductRepository get _repo => ref.read(productRepositoryProvider);

  // Re-fetch the (one-shot) list streams after a change.
  void _refresh() {
    ref.invalidate(allProductsProvider);
    ref.invalidate(categoryProductsProvider);
  }

  Future<void> create(ProductModel product) async {
    state = ProductManagementLoading();
    try {
      await _repo.createProduct(product);
      _refresh();
      state = ProductManagementSuccess('Product created.');
    } catch (e) {
      state = ProductManagementError(e.toString());
    }
  }

  Future<void> update(ProductModel product) async {
    state = ProductManagementLoading();
    try {
      await _repo.updateProduct(product);
      _refresh();
      state = ProductManagementSuccess('Product updated.');
    } catch (e) {
      state = ProductManagementError(e.toString());
    }
  }

  Future<void> delete(String productId) async {
    state = ProductManagementLoading();
    try {
      await _repo.deleteProduct(productId);
      _refresh();
      state = ProductManagementSuccess('Product deleted.');
    } catch (e) {
      state = ProductManagementError(e.toString());
    }
  }

  Future<void> updateStock({
    required String productId,
    required int quantity,
  }) async {
    state = ProductManagementLoading();
    try {
      await _repo.updateStock(productId: productId, quantity: quantity);
      state = ProductManagementSuccess('Stock updated.');
    } catch (e) {
      state = ProductManagementError(e.toString());
    }
  }

  void reset() => state = ProductManagementIdle();
}

final productManagementProvider =
    NotifierProvider<ProductManagementNotifier, ProductManagementState>(
        ProductManagementNotifier.new);
