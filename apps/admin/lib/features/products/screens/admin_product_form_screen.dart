import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spazalink_core/core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../categories/providers/category_provider.dart';
import '../providers/product_provider.dart';

class AdminProductFormScreen extends ConsumerStatefulWidget {
  const AdminProductFormScreen({super.key, this.product});

  /// null = create mode, non-null = edit mode
  final ProductModel? product;

  @override
  ConsumerState<AdminProductFormScreen> createState() =>
      _AdminProductFormScreenState();
}

class _AdminProductFormScreenState
    extends ConsumerState<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool get _isEdit => widget.product != null;

  // Controllers
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _sku;
  late final TextEditingController _packSize;
  late final TextEditingController _priceRand; // price in Rand (decimal input)
  late final TextEditingController _salePriceRand;
  late final TextEditingController _stock;
  late final TextEditingController _supplier;

  String? _selectedCategoryId;
  bool _isAvailable = true;
  bool _isFeatured = false;
  bool _hasSalePrice = false;

  List<String> _imageUrls = [];
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _sku = TextEditingController(text: p?.sku ?? '');
    _packSize = TextEditingController(text: p?.packSize ?? '');
    _priceRand = TextEditingController(
        text: p != null ? (p.priceCents / 100).toStringAsFixed(2) : '');
    _salePriceRand = TextEditingController(
        text: p?.salePriceCents != null
            ? (p!.salePriceCents! / 100).toStringAsFixed(2)
            : '');
    _stock = TextEditingController(text: '${p?.stockQuantity ?? 0}');
    _supplier = TextEditingController(text: p?.supplier ?? '');
    _selectedCategoryId = p?.categoryId;
    _isAvailable = p?.isAvailable ?? true;
    _isFeatured = p?.isFeatured ?? false;
    _hasSalePrice = p?.salePriceCents != null;
    _imageUrls = List<String>.from(p?.imageUrls ?? const []);
  }

  /// Pick an image and upload it to Supabase Storage, then keep its URL.
  Future<void> _pickAndUploadImage() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1400,
      );
      if (file == null) return;
      setState(() => _uploadingImage = true);

      final bytes = await file.readAsBytes();
      final ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
      final path = '${DateTime.now().millisecondsSinceEpoch}.$ext';
      final storage = Supabase.instance.client.storage.from('product_images');
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: file.mimeType ?? 'image/jpeg'),
      );
      final url = storage.getPublicUrl(path);
      if (!mounted) return;
      setState(() {
        _imageUrls.add(url);
        _uploadingImage = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Image upload failed: $e'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _sku.dispose();
    _packSize.dispose();
    _priceRand.dispose();
    _salePriceRand.dispose();
    _stock.dispose();
    _supplier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final mgmtState = ref.watch(productManagementProvider);
    final isBusy = mgmtState is ProductManagementLoading;

    ref.listen<ProductManagementState>(productManagementProvider, (_, next) {
      if (next is ProductManagementSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.brandGreenPrimary,
          ),
        );
        ref.read(productManagementProvider.notifier).reset();
        context.go(RouteConstants.adminProducts);
      } else if (next is ProductManagementError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(productManagementProvider.notifier).reset();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.adminDarkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.adminDarkSurface,
        elevation: 0,
        title: Text(
          _isEdit ? 'Edit Product' : 'Add Product',
          style: const TextStyle(
            color: AppColors.darkOnSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.darkOnSurface),
          onPressed: () => context.go(RouteConstants.adminProducts),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton(
              onPressed: isBusy ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandGreenPrimary,
                foregroundColor: AppColors.white,
                disabledBackgroundColor:
                    AppColors.adminDarkSurfaceVariant,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: isBusy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.white),
                    )
                  : Text(_isEdit ? 'Save Changes' : 'Create Product'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _FormCard(
                        title: 'Basic Info',
                        children: [
                          _FormField(
                            label: 'Product Name',
                            controller: _name,
                            required: true,
                            hint: 'e.g. Coca-Cola 2L',
                          ),
                          const SizedBox(height: 16),
                          // Category dropdown
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Category',
                                  style: TextStyle(
                                    color: AppColors.darkOnSurface,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  )),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedCategoryId,
                                dropdownColor: AppColors.adminDarkSurface,
                                style: const TextStyle(
                                  color: AppColors.darkOnSurface,
                                  fontSize: 13,
                                ),
                                decoration: _inputDecoration(hint: 'Select category'),
                                validator: (v) => v == null ? 'Required' : null,
                                items: categories
                                    .map((c) => DropdownMenuItem(
                                          value: c.id,
                                          child: Text(c.name),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedCategoryId = v),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _FormField(
                            label: 'Description',
                            controller: _description,
                            maxLines: 3,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _FormCard(
                        title: 'Pricing',
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _FormField(
                                  label: 'Price (R)',
                                  controller: _priceRand,
                                  required: true,
                                  hint: '0.00',
                                  inputType: const TextInputType
                                      .numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d{0,2}')),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text('Sale Price (R)',
                                            style: TextStyle(
                                              color: AppColors.darkOnSurface,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            )),
                                        const Spacer(),
                                        Switch(
                                          value: _hasSalePrice,
                                          onChanged: (v) => setState(
                                              () => _hasSalePrice = v),
                                          activeThumbColor:
                                              AppColors.brandGreenPrimary,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _salePriceRand,
                                      enabled: _hasSalePrice,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                            RegExp(r'^\d*\.?\d{0,2}')),
                                      ],
                                      style: const TextStyle(
                                        color: AppColors.darkOnSurface,
                                        fontSize: 13,
                                      ),
                                      decoration:
                                          _inputDecoration(hint: '0.00'),
                                      validator: _hasSalePrice
                                          ? (v) {
                                              if (v == null || v.isEmpty) {
                                                return 'Required';
                                              }
                                              return null;
                                            }
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Right column
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _FormCard(
                        title: 'Product Images',
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final url in _imageUrls)
                                _ImageThumb(
                                  url: url,
                                  onRemove: () =>
                                      setState(() => _imageUrls.remove(url)),
                                ),
                              _AddImageTile(
                                loading: _uploadingImage,
                                onTap: _uploadingImage
                                    ? null
                                    : _pickAndUploadImage,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _FormCard(
                        title: 'Inventory',
                        children: [
                          _FormField(
                            label: 'SKU',
                            controller: _sku,
                            hint: 'e.g. CC-2L-001',
                          ),
                          const SizedBox(height: 16),
                          _FormField(
                            label: 'Pack Size',
                            controller: _packSize,
                            hint: 'e.g. 6 × 2L',
                          ),
                          const SizedBox(height: 16),
                          _FormField(
                            label: 'Stock Quantity',
                            controller: _stock,
                            required: true,
                            hint: '0',
                            inputType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          const SizedBox(height: 16),
                          _FormField(
                            label: 'Supplier',
                            controller: _supplier,
                            hint: 'Optional',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _FormCard(
                        title: 'Visibility',
                        children: [
                          _ToggleRow(
                            label: 'Available for purchase',
                            value: _isAvailable,
                            onChanged: (v) =>
                                setState(() => _isAvailable = v),
                          ),
                          const SizedBox(height: 8),
                          _ToggleRow(
                            label: 'Top Deal (show on Home)',
                            value: _isFeatured,
                            onChanged: (v) =>
                                setState(() => _isFeatured = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final priceCents =
        (double.tryParse(_priceRand.text) ?? 0) * 100 ~/ 1;
    final saleCents = _hasSalePrice && _salePriceRand.text.isNotEmpty
        ? (double.tryParse(_salePriceRand.text) ?? 0) * 100 ~/ 1
        : null;
    final stock = int.tryParse(_stock.text) ?? 0;
    final now = DateTime.now();

    final product = ProductModel(
      id: widget.product?.id ?? '',
      categoryId: _selectedCategoryId!,
      name: _name.text.trim(),
      description: _description.text.trim(),
      sku: _sku.text.trim(),
      packSize: _packSize.text.trim(),
      priceCents: priceCents,
      salePriceCents: saleCents,
      stockQuantity: stock,
      supplier: _supplier.text.trim().isNotEmpty
          ? _supplier.text.trim()
          : null,
      isAvailable: _isAvailable,
      isFeatured: _isFeatured,
      imageUrls: _imageUrls,
      tags: widget.product?.tags ?? [],
      createdAt: widget.product?.createdAt ?? now,
      updatedAt: now,
    );

    if (_isEdit) {
      ref.read(productManagementProvider.notifier).update(product);
    } else {
      ref.read(productManagementProvider.notifier).create(product);
    }
  }
}

// ── Image widgets ─────────────────────────────────────────────────────────────

class _ImageThumb extends StatelessWidget {
  const _ImageThumb({required this.url, required this.onRemove});
  final String url;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            width: 84,
            height: 84,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 84,
              height: 84,
              color: AppColors.adminDarkSurfaceVariant,
              child: const Icon(Icons.broken_image_outlined,
                  color: AppColors.darkOnSurfaceVariant),
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(2),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddImageTile extends StatelessWidget {
  const _AddImageTile({required this.loading, required this.onTap});
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: AppColors.adminDarkSurfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.adminDarkOutline),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.brandGreenPrimary),
                )
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined,
                        color: AppColors.darkOnSurfaceVariant, size: 22),
                    SizedBox(height: 4),
                    Text('Add',
                        style: TextStyle(
                            color: AppColors.darkOnSurfaceVariant, fontSize: 11)),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Shared form sub-widgets ───────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  const _FormCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.adminDarkSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.adminDarkOutline),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.darkOnSurface,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.adminDarkOutline, height: 1),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    this.required = false,
    this.hint,
    this.maxLines = 1,
    this.inputType,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final bool required;
  final String? hint;
  final int maxLines;
  final TextInputType? inputType;
  final List<TextInputFormatter>? inputFormatters;

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
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: inputType,
          inputFormatters: inputFormatters,
          style: const TextStyle(
            color: AppColors.darkOnSurface,
            fontSize: 13,
          ),
          decoration: _inputDecoration(hint: hint ?? ''),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null,
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.darkOnSurface,
            fontSize: 13,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.brandGreenPrimary,
        ),
      ],
    );
  }
}

InputDecoration _inputDecoration({String hint = ''}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: AppColors.darkOnSurfaceVariant,
      fontSize: 13,
    ),
    filled: true,
    fillColor: AppColors.adminDarkSurfaceVariant,
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.adminDarkOutline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.adminDarkOutline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide:
          const BorderSide(color: AppColors.brandGreenPrimary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
  );
}
