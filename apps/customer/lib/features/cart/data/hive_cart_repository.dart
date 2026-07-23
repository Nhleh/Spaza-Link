import 'dart:async';
import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:spazalink_core/core.dart';

/// Hive-backed cart repository. Cart items are stored as JSON strings keyed
/// by "${shopId}:${productId}" so a customer can only have one cart at a time
/// and items from different shops stay isolated.
class HiveCartRepository implements CartRepository {
  static const _boxName = 'cart_items';

  final Box<String> _box;
  final _controllers = <String, StreamController<List<CartItemModel>>>{};

  HiveCartRepository._(this._box);

  static Future<HiveCartRepository> create() async {
    final box = await Hive.openBox<String>(_boxName);
    return HiveCartRepository._(box);
  }

  String _key(String shopId, String productId) => '$shopId:$productId';

  List<CartItemModel> _itemsForShop(String shopId) {
    return _box.keys
        .where((k) => (k as String).startsWith('$shopId:'))
        .map((k) {
          final raw = _box.get(k as String);
          if (raw == null) return null;
          try {
            return CartItemModel.fromJson(
                jsonDecode(raw) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<CartItemModel>()
        .toList();
  }

  void _notify(String shopId) {
    _controllers[shopId]?.add(_itemsForShop(shopId));
  }

  @override
  Stream<List<CartItemModel>> watchItems(String shopId) {
    _controllers[shopId] ??= StreamController<List<CartItemModel>>.broadcast(
      onListen: () => _notify(shopId),
    );
    return _controllers[shopId]!.stream;
  }

  @override
  Future<List<CartItemModel>> getItems(String shopId) async =>
      _itemsForShop(shopId);

  @override
  Future<void> upsertItem(CartItemModel item) async {
    final key = _key(item.shopId, item.productId);
    final existing = _box.get(key);
    CartItemModel toSave;
    if (existing != null) {
      final prev = CartItemModel.fromJson(
          jsonDecode(existing) as Map<String, dynamic>);
      toSave = prev.copyWith(quantity: item.quantity);
    } else {
      toSave = item;
    }
    await _box.put(key, jsonEncode(toSave.toJson()));
    _notify(item.shopId);
  }

  @override
  Future<void> removeItem({
    required String productId,
    required String shopId,
  }) async {
    await _box.delete(_key(shopId, productId));
    _notify(shopId);
  }

  @override
  Future<void> clearCart(String shopId) async {
    final keys = _box.keys
        .where((k) => (k as String).startsWith('$shopId:'))
        .toList();
    await _box.deleteAll(keys);
    _notify(shopId);
  }

  void dispose() {
    for (final c in _controllers.values) {
      c.close();
    }
    _controllers.clear();
  }
}
