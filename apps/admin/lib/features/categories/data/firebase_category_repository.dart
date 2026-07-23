import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spazalink_core/core.dart';

class FirebaseCategoryRepository implements CategoryRepository {
  FirebaseCategoryRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreConstants.colCategories);

  @override
  Stream<List<CategoryModel>> watchCategories() {
    return _col
        .orderBy(FirestoreConstants.fldSortOrder)
        .snapshots()
        .map((s) => s.docs.map(_fromDoc).toList());
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    final snap = await _col.orderBy(FirestoreConstants.fldSortOrder).get();
    return snap.docs.map(_fromDoc).toList();
  }

  @override
  Future<CategoryModel?> getCategory(String categoryId) async {
    final doc = await _col.doc(categoryId).get();
    if (!doc.exists || doc.data() == null) return null;
    return _fromDoc(doc);
  }

  @override
  Future<CategoryModel> createCategory(CategoryModel category) async {
    final ref = _col.doc();
    final now = DateTime.now();
    final updated = category.copyWith(id: ref.id, createdAt: now);
    await ref.set(_toMap(updated));
    return updated;
  }

  @override
  Future<void> updateCategory(CategoryModel category) {
    return _col.doc(category.id).update(_toMap(category));
  }

  @override
  Future<void> deleteCategory(String categoryId) {
    return _col.doc(categoryId).delete();
  }

  CategoryModel _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return CategoryModel(
      id: doc.id,
      name: (d['name'] as String?) ?? '',
      slug: (d['slug'] as String?) ?? '',
      iconUrl: (d['iconUrl'] as String?) ?? '',
      imageUrl: (d['imageUrl'] as String?) ?? '',
      sortOrder: (d['sortOrder'] as int?) ?? 0,
      isAvailable: (d['isAvailable'] as bool?) ?? true,
      productCount: (d['productCount'] as int?) ?? 0,
      createdAt: _ts(d['createdAt']),
    );
  }

  Map<String, dynamic> _toMap(CategoryModel c) => {
        'name': c.name,
        'slug': c.slug,
        'iconUrl': c.iconUrl,
        'imageUrl': c.imageUrl,
        'sortOrder': c.sortOrder,
        'isAvailable': c.isAvailable,
        'productCount': c.productCount,
        'createdAt': Timestamp.fromDate(c.createdAt),
      };

  DateTime _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return DateTime.now();
  }
}
