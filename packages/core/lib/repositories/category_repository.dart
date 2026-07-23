import '../models/category_model.dart';

abstract interface class CategoryRepository {
  Stream<List<CategoryModel>> watchCategories();
  Future<List<CategoryModel>> getCategories();
  Future<CategoryModel?> getCategory(String categoryId);
  Future<CategoryModel> createCategory(CategoryModel category);
  Future<void> updateCategory(CategoryModel category);
  Future<void> deleteCategory(String categoryId);
}
