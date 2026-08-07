import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:spazalink_core/core.dart';

import '../models/advertisement.dart';
import '../providers/admin_ads_provider.dart';

/// Advertisement management (spec #10): create, edit, delete, upload images,
/// activate/deactivate and schedule ads. Everything syncs to the customer app
/// through the shared `advertisements` table.
class AdminAdsScreen extends ConsumerWidget {
  const AdminAdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminAdsProvider);

    return Scaffold(
      backgroundColor: AppColors.adminDarkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.adminDarkSurface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Advertisements',
            style: TextStyle(
                color: AppColors.darkOnSurface, fontWeight: FontWeight.w700)),
        actions: [
          FilledButton.icon(
            onPressed: () => _openForm(context, ref, null),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Add Advertisement'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandGreenPrimary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.brandGreenPrimary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to load advertisements',
                  style: TextStyle(color: AppColors.darkOnSurface)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(adminAdsProvider),
                child: const Text('Retry',
                    style: TextStyle(color: AppColors.brandGreenPrimary)),
              ),
            ],
          ),
        ),
        data: (ads) {
          if (ads.isEmpty) {
            return const Center(
              child: Text(
                'No advertisements yet.\nAdd one to show a banner on the Shop page.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.darkOnSurfaceVariant),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: ads.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _AdRow(
              ad: ads[i],
              onEdit: () => _openForm(context, ref, ads[i]),
              onToggle: (v) => _toggle(context, ref, ads[i], v),
              onDelete: () => _confirmDelete(context, ref, ads[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openForm(
      BuildContext context, WidgetRef ref, Advertisement? existing) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _AdFormDialog(existing: existing),
    );
    if (saved == true) ref.invalidate(adminAdsProvider);
  }

  Future<void> _toggle(
      BuildContext context, WidgetRef ref, Advertisement ad, bool active) async {
    try {
      await ref.read(adminAdsRepositoryProvider).setActive(ad.id, active);
      ref.invalidate(adminAdsProvider);
    } catch (e) {
      if (context.mounted) _snack(context, 'Update failed: $e', error: true);
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Advertisement ad) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.adminDarkSurface,
        title: const Text('Delete advertisement?',
            style: TextStyle(color: AppColors.darkOnSurface)),
        content: Text(
          'This permanently removes "${ad.title.isEmpty ? 'this ad' : ad.title}". '
          'It will disappear from the Shop immediately.',
          style: const TextStyle(color: AppColors.darkOnSurfaceVariant),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(adminAdsRepositoryProvider).delete(ad.id);
      ref.invalidate(adminAdsProvider);
    } catch (e) {
      if (context.mounted) _snack(context, 'Delete failed: $e', error: true);
    }
  }
}

void _snack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: error ? AppColors.error : AppColors.brandGreenPrimary,
  ));
}

class _AdRow extends StatelessWidget {
  const _AdRow({
    required this.ad,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final Advertisement ad;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM yyyy');
    final schedule = [
      if (ad.startsAt != null) 'from ${df.format(ad.startsAt!)}',
      if (ad.endsAt != null) 'to ${df.format(ad.endsAt!)}',
    ].join(' ');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.adminDarkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkOutline),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 120,
              height: 68,
              color: AppColors.adminDarkBackground,
              child: ad.imageUrl.isEmpty
                  ? const Icon(Icons.image_not_supported_outlined,
                      color: AppColors.darkOnSurfaceVariant)
                  : Image.network(
                      ad.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.darkOnSurfaceVariant),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ad.title.isEmpty ? '(untitled)' : ad.title,
                    style: const TextStyle(
                        color: AppColors.darkOnSurface,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                _StatusChip(ad: ad),
                if (schedule.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(schedule,
                      style: const TextStyle(
                          color: AppColors.darkOnSurfaceVariant, fontSize: 12)),
                ],
              ],
            ),
          ),
          // Activate / deactivate
          Column(
            children: [
              Switch(
                value: ad.active,
                activeColor: AppColors.brandGreenPrimary,
                onChanged: onToggle,
              ),
              Text(ad.active ? 'Active' : 'Inactive',
                  style: const TextStyle(
                      color: AppColors.darkOnSurfaceVariant, fontSize: 11)),
            ],
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Edit',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded,
                color: AppColors.brandGreenPrimary, size: 20),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error, size: 20),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.ad});
  final Advertisement ad;

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;
    final now = DateTime.now();
    if (!ad.active) {
      label = 'Inactive';
      color = AppColors.darkOnSurfaceVariant;
    } else if (ad.startsAt != null && now.isBefore(ad.startsAt!)) {
      label = 'Scheduled';
      color = AppColors.brandGold;
    } else if (ad.endsAt != null && now.isAfter(ad.endsAt!)) {
      label = 'Expired';
      color = AppColors.error;
    } else {
      label = 'Live';
      color = AppColors.brandGreenPrimary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Create / edit dialog ────────────────────────────────────────────────────

class _AdFormDialog extends ConsumerStatefulWidget {
  const _AdFormDialog({this.existing});
  final Advertisement? existing;

  @override
  ConsumerState<_AdFormDialog> createState() => _AdFormDialogState();
}

class _AdFormDialogState extends ConsumerState<_AdFormDialog> {
  late final TextEditingController _title;
  late final TextEditingController _link;
  late final TextEditingController _sort;
  String _imageUrl = '';
  bool _active = true;
  DateTime? _startsAt;
  DateTime? _endsAt;
  bool _uploading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _link = TextEditingController(text: e?.linkUrl ?? '');
    _sort = TextEditingController(text: '${e?.sortOrder ?? 0}');
    _imageUrl = e?.imageUrl ?? '';
    _active = e?.active ?? true;
    _startsAt = e?.startsAt;
    _endsAt = e?.endsAt;
  }

  @override
  void dispose() {
    _title.dispose();
    _link.dispose();
    _sort.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final file = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1280);
      if (file == null) return;
      setState(() => _uploading = true);
      final bytes = await file.readAsBytes();
      final ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
      final url = await ref.read(adminAdsRepositoryProvider).uploadImage(
            bytes,
            ext: ext,
            contentType: file.mimeType,
          );
      if (!mounted) return;
      setState(() {
        _imageUrl = url;
        _uploading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      _snack(context, 'Image upload failed: $e', error: true);
    }
  }

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final initial = (start ? _startsAt : _endsAt) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startsAt = picked;
      } else {
        // End of the chosen day so an ad stays live through that date.
        _endsAt = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      }
    });
  }

  Future<void> _save() async {
    if (_imageUrl.isEmpty) {
      _snack(context, 'Please upload an advertisement image.', error: true);
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(adminAdsRepositoryProvider);
    final ad = Advertisement(
      id: widget.existing?.id ?? '',
      title: _title.text.trim(),
      imageUrl: _imageUrl,
      linkUrl: _link.text.trim(),
      active: _active,
      startsAt: _startsAt,
      endsAt: _endsAt,
      sortOrder: int.tryParse(_sort.text.trim()) ?? 0,
    );
    try {
      if (widget.existing == null) {
        await repo.create(ad);
      } else {
        await repo.update(ad);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack(context, 'Save failed: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM yyyy');
    return AlertDialog(
      backgroundColor: AppColors.adminDarkSurface,
      title: Text(widget.existing == null ? 'New advertisement' : 'Edit advertisement',
          style: const TextStyle(color: AppColors.darkOnSurface)),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image preview + upload
              GestureDetector(
                onTap: _uploading ? null : _pickImage,
                child: Container(
                  height: 130,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.adminDarkBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.darkOutline),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _uploading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.brandGreenPrimary))
                      : _imageUrl.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined,
                                      color: AppColors.darkOnSurfaceVariant,
                                      size: 30),
                                  SizedBox(height: 6),
                                  Text('Tap to upload image',
                                      style: TextStyle(
                                          color:
                                              AppColors.darkOnSurfaceVariant)),
                                ],
                              ),
                            )
                          : Image.network(_imageUrl, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 12),
              _field(_title, 'Title (optional)'),
              const SizedBox(height: 10),
              _field(_link, 'Link URL (optional)'),
              const SizedBox(height: 10),
              _field(_sort, 'Sort order', number: true),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'Start date',
                      value: _startsAt == null ? 'Any' : df.format(_startsAt!),
                      onTap: () => _pickDate(start: true),
                      onClear:
                          _startsAt == null ? null : () => setState(() => _startsAt = null),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DateField(
                      label: 'End date',
                      value: _endsAt == null ? 'Any' : df.format(_endsAt!),
                      onTap: () => _pickDate(start: false),
                      onClear:
                          _endsAt == null ? null : () => setState(() => _endsAt = null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _active,
                activeColor: AppColors.brandGreenPrimary,
                title: const Text('Active',
                    style: TextStyle(color: AppColors.darkOnSurface)),
                subtitle: const Text('Show this ad to customers',
                    style: TextStyle(color: AppColors.darkOnSurfaceVariant)),
                onChanged: (v) => setState(() => _active = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        FilledButton(
          style:
              FilledButton.styleFrom(backgroundColor: AppColors.brandGreenPrimary),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.white))
              : const Text('Save'),
        ),
      ],
    );
  }

  Widget _field(TextEditingController c, String label, {bool number = false}) {
    return TextField(
      controller: c,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: AppColors.darkOnSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.darkOnSurfaceVariant),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.brandGreenPrimary),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.darkOnSurfaceVariant),
          suffixIcon: onClear == null
              ? const Icon(Icons.calendar_today_rounded,
                  size: 16, color: AppColors.darkOnSurfaceVariant)
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  color: AppColors.darkOnSurfaceVariant,
                  onPressed: onClear,
                ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.darkOutline),
          ),
        ),
        child: Text(value, style: const TextStyle(color: AppColors.darkOnSurface)),
      ),
    );
  }
}
