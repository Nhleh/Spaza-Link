import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';

import '../providers/category_provider.dart';

class AdminCategoriesScreen extends ConsumerWidget {
  const AdminCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<CategoryManagementState>(categoryManagementProvider,
        (_, next) {
      if (next is CategoryManagementSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.brandGreenPrimary,
          ),
        );
        ref.read(categoryManagementProvider.notifier).reset();
      } else if (next is CategoryManagementError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(categoryManagementProvider.notifier).reset();
      }
    });

    final async = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.adminDarkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.adminDarkSurface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Categories',
          style: TextStyle(
            color: AppColors.darkOnSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          FilledButton.icon(
            onPressed: () => _showCategoryDialog(context, ref, null),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Add Category'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandGreenPrimary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: async.when(
        loading: () => const Center(
          child:
              CircularProgressIndicator(color: AppColors.brandGreenPrimary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Failed to load categories',
                  style: TextStyle(color: AppColors.darkOnSurface)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(categoriesProvider),
                child: const Text('Retry',
                    style:
                        TextStyle(color: AppColors.brandGreenPrimary)),
              ),
            ],
          ),
        ),
        data: (cats) {
          if (cats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.category_rounded,
                      size: 48,
                      color: AppColors.darkOnSurfaceVariant),
                  const SizedBox(height: 16),
                  const Text(
                    'No categories yet.',
                    style: TextStyle(color: AppColors.darkOnSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        _showCategoryDialog(context, ref, null),
                    child: const Text('Add the first category',
                        style: TextStyle(
                            color: AppColors.brandGreenPrimary)),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final cat = cats[i];
              return _CategoryTile(
                category: cat,
                onEdit: () => _showCategoryDialog(context, ref, cat),
                onDelete: () =>
                    _confirmDelete(context, ref, cat),
                onToggle: (v) {
                  ref
                      .read(categoryManagementProvider.notifier)
                      .update(cat.copyWith(isAvailable: v));
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    CategoryModel? existing,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _CategoryDialog(
        existing: existing,
        onSave: (cat) {
          if (existing == null) {
            ref.read(categoryManagementProvider.notifier).create(cat);
          } else {
            ref.read(categoryManagementProvider.notifier).update(cat);
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CategoryModel cat,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.adminDarkSurface,
        title: const Text('Delete category?',
            style: TextStyle(color: AppColors.darkOnSurface)),
        content: Text(
          'Deleting "${cat.name}" will not remove its products, but they will become uncategorised.',
          style: const TextStyle(
              color: AppColors.darkOnSurfaceVariant, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style:
                    TextStyle(color: AppColors.darkOnSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref
          .read(categoryManagementProvider.notifier)
          .delete(cat.id);
    }
  }
}

// ── Category tile ─────────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final CategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.adminDarkSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.adminDarkOutline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Icon / colour swatch
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.adminDarkSurfaceVariant,
              borderRadius: BorderRadius.circular(8),
              image: category.iconUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(category.iconUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: category.iconUrl.isEmpty
                ? const Icon(Icons.category_rounded,
                    size: 18,
                    color: AppColors.darkOnSurfaceVariant)
                : null,
          ),
          const SizedBox(width: 12),

          // Name + slug
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    color: AppColors.darkOnSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  category.slug,
                  style: const TextStyle(
                    color: AppColors.darkOnSurfaceVariant,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          // Product count chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.adminDarkSurfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${category.productCount} products',
              style: const TextStyle(
                color: AppColors.darkOnSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Available toggle
          Switch(
            value: category.isAvailable,
            onChanged: onToggle,
            activeThumbColor: AppColors.brandGreenPrimary,
          ),
          const SizedBox(width: 4),

          // Edit / delete buttons
          IconButton(
            icon: const Icon(Icons.edit_rounded,
                size: 16, color: AppColors.darkOnSurfaceVariant),
            tooltip: 'Edit',
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                size: 16, color: AppColors.error),
            tooltip: 'Delete',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ── Category dialog ───────────────────────────────────────────────────────────

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({required this.existing, required this.onSave});
  final CategoryModel? existing;
  final ValueChanged<CategoryModel> onSave;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _slug;
  late final TextEditingController _sortOrder;
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _slug = TextEditingController(text: e?.slug ?? '');
    _sortOrder =
        TextEditingController(text: '${e?.sortOrder ?? 0}');
    _isAvailable = e?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    _sortOrder.dispose();
    super.dispose();
  }

  void _autoSlug(String name) {
    if (widget.existing == null) {
      _slug.text = name
          .toLowerCase()
          .trim()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return AlertDialog(
      backgroundColor: AppColors.adminDarkSurface,
      title: Text(
        isEdit ? 'Edit Category' : 'Add Category',
        style: const TextStyle(color: AppColors.darkOnSurface),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(
                label: 'Name',
                controller: _name,
                required: true,
                onChanged: _autoSlug,
              ),
              const SizedBox(height: 12),
              _DialogField(
                label: 'Slug',
                controller: _slug,
                required: true,
                hint: 'kebab-case',
              ),
              const SizedBox(height: 12),
              _DialogField(
                label: 'Sort Order',
                controller: _sortOrder,
                hint: '0',
                inputType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Available',
                      style: TextStyle(
                        color: AppColors.darkOnSurface,
                        fontSize: 13,
                      )),
                  Switch(
                    value: _isAvailable,
                    onChanged: (v) =>
                        setState(() => _isAvailable = v),
                    activeThumbColor: AppColors.brandGreenPrimary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style:
                  TextStyle(color: AppColors.darkOnSurfaceVariant)),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brandGreenPrimary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(isEdit ? 'Save' : 'Create'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final cat = CategoryModel(
      id: widget.existing?.id ?? '',
      name: _name.text.trim(),
      slug: _slug.text.trim(),
      sortOrder: int.tryParse(_sortOrder.text) ?? 0,
      isAvailable: _isAvailable,
      iconUrl: widget.existing?.iconUrl ?? '',
      imageUrl: widget.existing?.imageUrl ?? '',
      productCount: widget.existing?.productCount ?? 0,
      createdAt: widget.existing?.createdAt ?? now,
    );
    widget.onSave(cat);
    Navigator.pop(context);
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.label,
    required this.controller,
    this.required = false,
    this.hint,
    this.inputType,
    this.onChanged,
  });
  final String label;
  final TextEditingController controller;
  final bool required;
  final String? hint;
  final TextInputType? inputType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.darkOnSurface,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: inputType,
          onChanged: onChanged,
          style: const TextStyle(
              color: AppColors.darkOnSurface, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.darkOnSurfaceVariant,
              fontSize: 13,
            ),
            filled: true,
            fillColor: AppColors.adminDarkSurfaceVariant,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: AppColors.adminDarkOutline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: AppColors.adminDarkOutline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: AppColors.brandGreenPrimary, width: 1.5),
            ),
          ),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty)
                  ? 'Required'
                  : null
              : null,
        ),
      ],
    );
  }
}
