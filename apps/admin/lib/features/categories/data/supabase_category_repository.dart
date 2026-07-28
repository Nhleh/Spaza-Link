import 'package:spazalink_core/core.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

class SupabaseCategoryRepository implements CategoryRepository {
  SupabaseCategoryRepository({supa.SupabaseClient? client})
      : _sb = client ?? supa.Supabase.instance.client;

  final supa.SupabaseClient _sb;

  @override
  Stream<List<CategoryModel>> watchCategories() async* {
    yield await getCategories();
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    final rows =
        await _sb.from('categories').select().order('sort_order', ascending: true);
    return (rows as List).map((e) => _fromRow(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<CategoryModel?> getCategory(String categoryId) async {
    final row = await _sb
        .from('categories')
        .select()
        .eq('id', categoryId)
        .maybeSingle();
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<CategoryModel> createCategory(CategoryModel category) async {
    final row = await _sb
        .from('categories')
        .upsert(_toRow(category))
        .select()
        .single();
    return _fromRow(row);
  }

  @override
  Future<void> updateCategory(CategoryModel category) async {
    await _sb.from('categories').update(_toRow(category)).eq('id', category.id);
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await _sb.from('categories').delete().eq('id', categoryId);
  }

  // ── Mapping ──────────────────────────────────────────────────────────────────
  CategoryModel _fromRow(Map<String, dynamic> d) => CategoryModel(
        id: d['id'] as String,
        name: (d['name'] as String?) ?? '',
        slug: (d['slug'] as String?) ?? (d['id'] as String),
        iconUrl: (d['icon_url'] as String?) ?? '',
        imageUrl: (d['image_url'] as String?) ?? '',
        sortOrder: (d['sort_order'] as num?)?.toInt() ?? 0,
        isAvailable: (d['is_available'] as bool?) ?? true,
        productCount: (d['product_count'] as num?)?.toInt() ?? 0,
        createdAt:
            d['created_at'] is String ? DateTime.tryParse(d['created_at']) ?? DateTime.now() : DateTime.now(),
      );

  Map<String, dynamic> _toRow(CategoryModel c) {
    final id = c.id.isNotEmpty ? c.id : c.slug;
    return {
      'id': id,
      'name': c.name,
      'slug': c.slug.isNotEmpty ? c.slug : id,
      'icon_url': c.iconUrl,
      'image_url': c.imageUrl,
      'sort_order': c.sortOrder,
      'is_available': c.isAvailable,
      'product_count': c.productCount,
    };
  }
}
