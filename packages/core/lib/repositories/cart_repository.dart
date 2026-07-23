import '../models/cart_item_model.dart';

abstract interface class CartRepository {
  /// Live stream of cart items for [shopId].
  Stream<List<CartItemModel>> watchItems(String shopId);

  Future<List<CartItemModel>> getItems(String shopId);

  /// Adds item if not present; updates quantity if already in cart.
  Future<void> upsertItem(CartItemModel item);

  Future<void> removeItem({required String productId, required String shopId});

  /// Removes all items for [shopId] (called after successful order placement).
  Future<void> clearCart(String shopId);
}
