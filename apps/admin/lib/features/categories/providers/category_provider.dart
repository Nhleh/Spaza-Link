import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';

import '../data/supabase_category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return SupabaseCategoryRepository();
});

final categoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchCategories();
});

// ── Admin category management notifier ───────────────────────────────────────

sealed class CategoryManagementState {}

class CategoryManagementIdle extends CategoryManagementState {}

class CategoryManagementLoading extends CategoryManagementState {}

class CategoryManagementSuccess extends CategoryManagementState {
  CategoryManagementSuccess(this.message);
  final String message;
}

class CategoryManagementError extends CategoryManagementState {
  CategoryManagementError(this.message);
  final String message;
}

class CategoryManagementNotifier extends Notifier<CategoryManagementState> {
  @override
  CategoryManagementState build() => CategoryManagementIdle();

  CategoryRepository get _repo => ref.read(categoryRepositoryProvider);

  Future<void> create(CategoryModel category) async {
    state = CategoryManagementLoading();
    try {
      await _repo.createCategory(category);
      ref.invalidate(categoriesProvider);
      state = CategoryManagementSuccess('Category created.');
    } catch (e) {
      state = CategoryManagementError(e.toString());
    }
  }

  Future<void> update(CategoryModel category) async {
    state = CategoryManagementLoading();
    try {
      await _repo.updateCategory(category);
      ref.invalidate(categoriesProvider);
      state = CategoryManagementSuccess('Category updated.');
    } catch (e) {
      state = CategoryManagementError(e.toString());
    }
  }

  Future<void> delete(String categoryId) async {
    state = CategoryManagementLoading();
    try {
      await _repo.deleteCategory(categoryId);
      ref.invalidate(categoriesProvider);
      state = CategoryManagementSuccess('Category deleted.');
    } catch (e) {
      state = CategoryManagementError(e.toString());
    }
  }

  void reset() => state = CategoryManagementIdle();
}

final categoryManagementProvider =
    NotifierProvider<CategoryManagementNotifier, CategoryManagementState>(
        CategoryManagementNotifier.new);
