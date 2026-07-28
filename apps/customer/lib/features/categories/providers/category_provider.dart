import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';

import '../data/supabase_category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return SupabaseCategoryRepository();
});

final categoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchCategories();
});

final categoryProvider =
    FutureProvider.family<CategoryModel?, String>((ref, id) {
  return ref.watch(categoryRepositoryProvider).getCategory(id);
});
