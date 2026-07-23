import '../models/product_model.dart';

abstract interface class ProductRepository {
  /// Real-time stream of products, optionally filtered by category.
  Stream<List<ProductModel>> watchProducts({
    String? categoryId,
    bool featuredOnly = false,
  });

  /// Paginated product fetch. Pass [startAfterId] for next-page cursor.
  Future<List<ProductModel>> getProducts({
    String? categoryId,
    int limit = 20,
    String? startAfterId,
  });

  Future<ProductModel?> getProduct(String productId);

  /// Full-text search (client-side filter on cached data).
  Future<List<ProductModel>> searchProducts(String query);

  Future<ProductModel> createProduct(ProductModel product);
  Future<void> updateProduct(ProductModel product);
  Future<void> deleteProduct(String productId);
  Future<void> updateStock({required String productId, required int quantity});
}
