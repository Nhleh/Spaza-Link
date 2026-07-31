import 'package:spazalink_core/core.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

class SupabaseProductRepository implements ProductRepository {
  SupabaseProductRepository({supa.SupabaseClient? client})
      : _sb = client ?? supa.Supabase.instance.client;

  final supa.SupabaseClient _sb;

  // One-shot stream (re-run by invalidating the provider after a mutation).
  @override
  Stream<List<ProductModel>> watchProducts({
    String? categoryId,
    bool featuredOnly = false,
  }) async* {
    yield await getProducts(categoryId: categoryId);
  }

  @override
  Future<List<ProductModel>> getProducts({
    String? categoryId,
    int limit = 20,
    String? startAfterId,
  }) async {
    var q = _sb.from('products').select();
    if (categoryId != null) q = q.eq('category_id', categoryId);
    final rows = await q.order('created_at', ascending: false).limit(limit);
    return (rows as List).map((e) => _fromRow(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<ProductModel?> getProduct(String productId) async {
    final row =
        await _sb.from('products').select().eq('id', productId).maybeSingle();
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    final rows = await _sb
        .from('products')
        .select()
        .ilike('name', '%$query%')
        .limit(50);
    return (rows as List).map((e) => _fromRow(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<ProductModel> createProduct(ProductModel product) async {
    final row =
        await _sb.from('products').insert(_toRow(product)).select().single();
    return _fromRow(row);
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    await _sb.from('products').update(
        _toRow(product)..['updated_at'] = DateTime.now().toIso8601String())
        .eq('id', product.id);
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await _sb.from('products').delete().eq('id', productId);
  }

  @override
  Future<void> updateStock(
      {required String productId, required int quantity}) async {
    await _sb.from('products').update({
      'stock_quantity': quantity,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', productId);
  }

  // ── Mapping ──────────────────────────────────────────────────────────────────
  ProductModel _fromRow(Map<String, dynamic> d) => ProductModel(
        id: d['id'] as String,
        categoryId: (d['category_id'] as String?) ?? '',
        name: (d['name'] as String?) ?? '',
        description: (d['description'] as String?) ?? '',
        sku: (d['sku'] as String?) ?? '',
        barcode: d['barcode'] as String?,
        imageUrls: (d['image_urls'] as List?)?.cast<String>() ?? const [],
        // Prices in the DB are the admin's BASE price. Customers pay the base
        // price plus the 15% markup (the platform's profit), so mark it up here
        // once — every downstream view (cards, cart, checkout, orders) then uses
        // the customer-facing price automatically.
        priceCents: AppConstants.customerPriceCents(
            (d['price_cents'] as num?)?.toInt() ?? 0),
        salePriceCents: d['sale_price_cents'] == null
            ? null
            : AppConstants.customerPriceCents((d['sale_price_cents'] as num).toInt()),
        packSize: (d['pack_size'] as String?) ?? '',
        stockQuantity: (d['stock_quantity'] as num?)?.toInt() ?? 0,
        weightGrams: (d['weight_grams'] as num?)?.toInt(),
        supplier: d['supplier'] as String?,
        isFeatured: (d['is_featured'] as bool?) ?? false,
        isAvailable: (d['is_available'] as bool?) ?? true,
        tags: (d['tags'] as List?)?.cast<String>() ?? const [],
        createdAt: _dt(d['created_at']),
        updatedAt: _dt(d['updated_at']),
      );

  Map<String, dynamic> _toRow(ProductModel p) {
    final m = <String, dynamic>{
      'category_id': p.categoryId,
      'name': p.name,
      'description': p.description,
      'sku': p.sku,
      'barcode': p.barcode,
      'image_urls': p.imageUrls,
      'price_cents': p.priceCents,
      'sale_price_cents': p.salePriceCents,
      'pack_size': p.packSize,
      'stock_quantity': p.stockQuantity,
      'weight_grams': p.weightGrams,
      'supplier': p.supplier,
      'is_featured': p.isFeatured,
      'is_available': p.isAvailable,
      'tags': p.tags,
    };
    if (p.id.isNotEmpty) m['id'] = p.id;
    return m;
  }

  DateTime _dt(dynamic v) =>
      v is String ? (DateTime.tryParse(v) ?? DateTime.now()) : DateTime.now();
}
