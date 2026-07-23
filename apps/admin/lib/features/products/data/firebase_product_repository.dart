import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spazalink_core/core.dart';

class FirebaseProductRepository implements ProductRepository {
  FirebaseProductRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreConstants.colProducts);

  @override
  Stream<List<ProductModel>> watchProducts({
    String? categoryId,
    bool featuredOnly = false,
  }) {
    Query<Map<String, dynamic>> q = _col.orderBy('name');
    if (categoryId != null) q = q.where('categoryId', isEqualTo: categoryId);
    if (featuredOnly) q = q.where('isFeatured', isEqualTo: true);
    return q.snapshots().map((s) => s.docs.map(_fromDoc).toList());
  }

  @override
  Future<List<ProductModel>> getProducts({
    String? categoryId,
    int limit = 20,
    String? startAfterId,
  }) async {
    Query<Map<String, dynamic>> q = _col.orderBy('name').limit(limit);
    if (categoryId != null) q = q.where('categoryId', isEqualTo: categoryId);
    if (startAfterId != null) {
      final cursor = await _col.doc(startAfterId).get();
      if (cursor.exists) q = q.startAfterDocument(cursor);
    }
    final snap = await q.get();
    return snap.docs.map(_fromDoc).toList();
  }

  @override
  Future<ProductModel?> getProduct(String productId) async {
    final doc = await _col.doc(productId).get();
    if (!doc.exists || doc.data() == null) return null;
    return _fromDoc(doc);
  }

  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    final snap = await _col.get();
    final lower = query.toLowerCase();
    return snap.docs
        .map(_fromDoc)
        .where((p) =>
            p.name.toLowerCase().contains(lower) ||
            p.sku.toLowerCase().contains(lower))
        .toList();
  }

  @override
  Future<ProductModel> createProduct(ProductModel product) async {
    final ref = _col.doc();
    final now = DateTime.now();
    final updated = product.copyWith(id: ref.id, createdAt: now, updatedAt: now);
    await ref.set(_toMap(updated));
    return updated;
  }

  @override
  Future<void> updateProduct(ProductModel product) {
    final map = _toMap(product)..['updatedAt'] = Timestamp.fromDate(DateTime.now());
    return _col.doc(product.id).update(map);
  }

  @override
  Future<void> deleteProduct(String productId) {
    return _col.doc(productId).delete();
  }

  @override
  Future<void> updateStock({required String productId, required int quantity}) {
    return _col.doc(productId).update({
      'stockQuantity': quantity,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  ProductModel _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return ProductModel(
      id: doc.id,
      categoryId: (d['categoryId'] as String?) ?? '',
      name: (d['name'] as String?) ?? '',
      description: (d['description'] as String?) ?? '',
      sku: (d['sku'] as String?) ?? '',
      barcode: d['barcode'] as String?,
      imageUrls: List<String>.from(d['imageUrls'] ?? []),
      priceCents: (d['priceCents'] as int?) ?? 0,
      salePriceCents: d['salePriceCents'] as int?,
      packSize: (d['packSize'] as String?) ?? '',
      stockQuantity: (d['stockQuantity'] as int?) ?? 0,
      weightGrams: d['weightGrams'] as int?,
      supplier: d['supplier'] as String?,
      isFeatured: (d['isFeatured'] as bool?) ?? false,
      isAvailable: (d['isAvailable'] as bool?) ?? true,
      tags: List<String>.from(d['tags'] ?? []),
      createdAt: _ts(d['createdAt']),
      updatedAt: _ts(d['updatedAt']),
    );
  }

  Map<String, dynamic> _toMap(ProductModel p) => {
        'categoryId': p.categoryId,
        'name': p.name,
        'description': p.description,
        'sku': p.sku,
        'barcode': p.barcode,
        'imageUrls': p.imageUrls,
        'priceCents': p.priceCents,
        'salePriceCents': p.salePriceCents,
        'packSize': p.packSize,
        'stockQuantity': p.stockQuantity,
        'weightGrams': p.weightGrams,
        'supplier': p.supplier,
        'isFeatured': p.isFeatured,
        'isAvailable': p.isAvailable,
        'tags': p.tags,
        'createdAt': Timestamp.fromDate(p.createdAt),
        'updatedAt': Timestamp.fromDate(p.updatedAt),
      };

  DateTime _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return DateTime.now();
  }
}
