import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spazalink_core/core.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/profile_service.dart';

// Shared scaffold for the edit screens.
class _EditScaffold extends StatelessWidget {
  const _EditScaffold({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.brandGreenPrimary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: child,
        ),
      ),
    );
  }
}

InputDecoration _dec(String label, {String? hint}) => InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.lightOutlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.lightOutlineVariant),
      ),
    );

Widget _saveButton({required bool busy, required VoidCallback onPressed}) {
  return SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton(
      onPressed: busy ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandGreenPrimary,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      child: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.white))
          : const Text('Save',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    ),
  );
}

void _toast(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: error ? AppColors.error : AppColors.brandGreenPrimary,
  ));
}

// ════════════════════════════════════════════════════════════════════════════
// Shop Information — edits shop + personal details, saved to Supabase.
// ════════════════════════════════════════════════════════════════════════════
class ShopInformationScreen extends ConsumerStatefulWidget {
  const ShopInformationScreen({super.key});
  @override
  ConsumerState<ShopInformationScreen> createState() =>
      _ShopInformationScreenState();
}

class _ShopInformationScreenState
    extends ConsumerState<ShopInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopName = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _province = TextEditingController();
  final _ownerName = TextEditingController();
  final _phone = TextEditingController();
  bool _busy = false;
  bool _loaded = false;
  String? _photoUrl;
  bool _uploadingPhoto = false;

  @override
  void dispose() {
    for (final c in [_shopName, _address, _city, _province, _ownerName, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  void _hydrate(ShopModel? shop, UserModel? user) {
    if (_loaded) return;
    _shopName.text = shop?.shopName ?? '';
    _address.text = shop?.physicalAddress ?? '';
    _city.text = shop?.city ?? '';
    _province.text = shop?.province ?? '';
    _ownerName.text = user?.displayName ?? shop?.ownerName ?? '';
    _phone.text = user?.phoneNumber ?? '';
    _photoUrl = shop?.shopPhotoUrl;
    _loaded = true;
  }

  Future<void> _pickPhoto(ShopModel? shop) async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
      );
      if (file == null) return;
      setState(() => _uploadingPhoto = true);
      final bytes = await file.readAsBytes();
      final svc = ref.read(profileServiceProvider);
      final url =
          await svc.uploadShopPhoto(bytes, file.mimeType ?? 'image/jpeg');
      // Persist immediately if we already have a shop.
      if (shop != null) {
        await svc.updateShop(shop.id, shopPhotoUrl: url);
        ref.invalidate(currentShopProvider);
      }
      if (!mounted) return;
      setState(() {
        _photoUrl = url;
        _uploadingPhoto = false;
      });
      _toast(context, 'Shop photo updated.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      _toast(context, 'Could not upload photo: $e', error: true);
    }
  }

  Future<void> _save(ShopModel? shop) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final svc = ref.read(profileServiceProvider);
      if (shop != null) {
        await svc.updateShop(
          shop.id,
          shopName: _shopName.text,
          physicalAddress: _address.text,
          city: _city.text,
          province: _province.text,
          shopPhotoUrl: _photoUrl,
        );
      }
      await svc.updateProfile(
        displayName: _ownerName.text,
        phoneNumber: _phone.text,
      );
      ref.invalidate(currentShopProvider);
      ref.invalidate(currentUserProvider);
      if (!mounted) return;
      _toast(context, 'Saved. Your details are updated.');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) _toast(context, 'Could not save: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = ref.watch(currentShopProvider).valueOrNull;
    final user = ref.watch(currentUserProvider).valueOrNull;
    _hydrate(shop, user);

    return _EditScaffold(
      title: 'Shop Information',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.brandGreenSurface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(color: AppColors.lightOutlineVariant),
                    ),
                    child: _uploadingPhoto
                        ? const Center(
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : (_photoUrl == null || _photoUrl!.isEmpty)
                            ? const Icon(Icons.storefront_rounded,
                                size: 44, color: AppColors.brandGreenPrimary)
                            : CachedNetworkImage(
                                imageUrl: _photoUrl!, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextButton.icon(
                    onPressed: _uploadingPhoto ? null : () => _pickPhoto(shop),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: Text((_photoUrl == null || _photoUrl!.isEmpty)
                        ? 'Upload shop photo'
                        : 'Change shop photo'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.brandGreenPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const _SectionLabel('Shop'),
            TextFormField(
              controller: _shopName,
              decoration: _dec('Shop name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
                controller: _address, decoration: _dec('Physical address')),
            const SizedBox(height: AppSpacing.md),
            Row(children: [
              Expanded(
                  child: TextFormField(
                      controller: _city, decoration: _dec('City'))),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                  child: TextFormField(
                      controller: _province, decoration: _dec('Province'))),
            ]),
            const SizedBox(height: AppSpacing.xl),
            const _SectionLabel('Owner'),
            TextFormField(
                controller: _ownerName, decoration: _dec('Your full name')),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: _dec('Cellphone number'),
            ),
            const SizedBox(height: AppSpacing.x3l),
            _saveButton(busy: _busy, onPressed: () => _save(shop)),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Text(
          text.toUpperCase(),
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.lightOnSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      );
}

// ════════════════════════════════════════════════════════════════════════════
// Change Password
// ════════════════════════════════════════════════════════════════════════════
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(profileServiceProvider).updatePassword(_pass.text);
      if (!mounted) return;
      _toast(context, 'Password changed.');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) _toast(context, 'Could not change password: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _EditScaffold(
      title: 'Change Password',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _pass,
              obscureText: _obscure,
              decoration: _dec('New password').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => (v == null || v.length < 6)
                  ? 'At least 6 characters'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _confirm,
              obscureText: _obscure,
              decoration: _dec('Confirm new password'),
              validator: (v) =>
                  v != _pass.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: AppSpacing.x3l),
            _saveButton(busy: _busy, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Notification Settings — toggles saved to profile.preferences
// ════════════════════════════════════════════════════════════════════════════
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});
  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  Map<String, dynamic> _prefs = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await ref.read(profileServiceProvider).getPreferences();
    if (!mounted) return;
    setState(() {
      _prefs = Map<String, dynamic>.from(p);
      _loading = false;
    });
  }

  Future<void> _set(String key, bool value) async {
    setState(() => _prefs[key] = value);
    try {
      await ref.read(profileServiceProvider).setPreferences(_prefs);
    } catch (e) {
      if (mounted) _toast(context, 'Could not save: $e', error: true);
    }
  }

  bool _get(String key) => _prefs[key] as bool? ?? true;

  @override
  Widget build(BuildContext context) {
    return _EditScaffold(
      title: 'Notification Settings',
      child: _loading
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.x3l),
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              children: [
                _switch('order_updates', 'Order updates',
                    'Status changes on your orders'),
                _switch('delivery_alerts', 'Delivery alerts',
                    'When a delivery is on the way'),
                _switch('promotions', 'Promotions & deals',
                    'Specials and price drops'),
                _switch('admin_messages', 'Messages from SpazaLink',
                    'Announcements from the SpazaLink team'),
              ],
            ),
    );
  }

  Widget _switch(String key, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.lightOutlineVariant),
      ),
      child: SwitchListTile(
        value: _get(key),
        activeThumbColor: AppColors.brandGreenPrimary,
        onChanged: (v) => _set(key, v),
        title: Text(title,
            style: AppTypography.bodyLarge
                .copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.lightOnSurfaceVariant)),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Delivery Addresses — primary (from shop) + editable delivery note/address
// ════════════════════════════════════════════════════════════════════════════
class DeliveryAddressesScreen extends ConsumerStatefulWidget {
  const DeliveryAddressesScreen({super.key});
  @override
  ConsumerState<DeliveryAddressesScreen> createState() =>
      _DeliveryAddressesScreenState();
}

class _DeliveryAddressesScreenState
    extends ConsumerState<DeliveryAddressesScreen> {
  final _delivery = TextEditingController();
  bool _busy = false;
  bool _loaded = false;

  @override
  void dispose() {
    _delivery.dispose();
    super.dispose();
  }

  Future<void> _save(ShopModel shop) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(profileServiceProvider)
          .updateShop(shop.id, deliveryAddress: _delivery.text);
      ref.invalidate(currentShopProvider);
      if (!mounted) return;
      _toast(context, 'Delivery address saved.');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) _toast(context, 'Could not save: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = ref.watch(currentShopProvider).valueOrNull;
    if (shop == null) {
      return const _EditScaffold(
        title: 'Delivery Addresses',
        child: Text('Register a shop first to set delivery addresses.'),
      );
    }
    if (!_loaded) {
      _loaded = true;
      // Pre-fill the saved alternate address (not on the typed model — read direct).
      ref
          .read(profileServiceProvider)
          .getShopDeliveryAddress(shop.id)
          .then((v) {
        if (mounted && _delivery.text.isEmpty) _delivery.text = v;
      });
    }
    final primary = [
      shop.physicalAddress,
      [shop.city, shop.province].where((s) => s.isNotEmpty).join(', ')
    ].where((s) => s.isNotEmpty).join(', ');

    return _EditScaffold(
      title: 'Delivery Addresses',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Primary (shop address)'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.lightOutlineVariant),
            ),
            child: Row(children: [
              const Icon(Icons.location_on_rounded,
                  color: AppColors.brandGreenPrimary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                  child: Text(primary.isEmpty ? 'No shop address yet' : primary,
                      style: AppTypography.bodyMedium)),
            ]),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _SectionLabel('Alternate delivery address'),
          TextField(
            controller: _delivery,
            maxLines: 3,
            decoration: _dec('Where should we deliver?',
                hint: 'e.g. gate code, nearby landmark, alternate address'),
          ),
          const SizedBox(height: AppSpacing.x3l),
          _saveButton(busy: _busy, onPressed: () => _save(shop)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Payment Methods — choose a preferred method (no card data is stored)
// ════════════════════════════════════════════════════════════════════════════
class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});
  @override
  ConsumerState<PaymentMethodsScreen> createState() =>
      _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  static const _methods = {
    'cod': ('Cash on Delivery', Icons.payments_outlined),
    'eft': ('EFT / Bank Transfer', Icons.account_balance_outlined),
  };
  String _selected = 'cod';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await ref.read(profileServiceProvider).getPreferences();
    if (!mounted) return;
    setState(() {
      _selected = (p['payment_method'] as String?) ?? 'cod';
      _loading = false;
    });
  }

  Future<void> _select(String key) async {
    setState(() => _selected = key);
    try {
      final svc = ref.read(profileServiceProvider);
      final prefs = await svc.getPreferences();
      prefs['payment_method'] = key;
      await svc.setPreferences(prefs);
      if (mounted) _toast(context, 'Payment method updated.');
    } catch (e) {
      if (mounted) _toast(context, 'Could not save: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _EditScaffold(
      title: 'Payment Methods',
      child: _loading
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.x3l),
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose how you\'d like to pay for orders. '
                  'For your security, card details are never stored in the app.',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.lightOnSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final e in _methods.entries)
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: _selected == e.key
                            ? AppColors.brandGreenPrimary
                            : AppColors.lightOutlineVariant,
                        width: _selected == e.key ? 2 : 1,
                      ),
                    ),
                    child: RadioListTile<String>(
                      value: e.key,
                      groupValue: _selected,
                      activeColor: AppColors.brandGreenPrimary,
                      onChanged: (v) => _select(v!),
                      title: Row(children: [
                        Icon(e.value.$2,
                            size: 20, color: AppColors.brandGreenPrimary),
                        const SizedBox(width: AppSpacing.md),
                        Text(e.value.$1,
                            style: AppTypography.bodyLarge
                                .copyWith(fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
              ],
            ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Help & Support
// ════════════════════════════════════════════════════════════════════════════
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _EditScaffold(
      title: 'Help & Support',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('We\'re here to help',
              style: AppTypography.titleLarge
                  .copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Reach the SpazaLink team for anything about your shop, orders or '
            'deliveries.',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.lightOnSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xl),
          _contactTile(Icons.phone_rounded, 'Call us', '0800 000 000'),
          _contactTile(Icons.chat_rounded, 'WhatsApp', '072 000 0000'),
          _contactTile(
              Icons.email_rounded, 'Email', 'support@spazalink.co.za'),
          const SizedBox(height: AppSpacing.xl),
          const _SectionLabel('Common questions'),
          _faq('When is my shop approved?',
              'An admin reviews new shops. You can browse right away; ordering unlocks once approved.'),
          _faq('How do deliveries work?',
              'Place an order and we schedule delivery to your shop address. Track it under Orders.'),
          _faq('How do I change my details?',
              'Tap Shop Information on your profile to update your shop and contact details.'),
        ],
      ),
    );
  }

  Widget _contactTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.lightOutlineVariant),
      ),
      child: Row(children: [
        Icon(icon, color: AppColors.brandGreenPrimary),
        const SizedBox(width: AppSpacing.md),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.lightOnSurfaceVariant)),
          Text(value,
              style: AppTypography.bodyLarge
                  .copyWith(fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }

  Widget _faq(String q, String a) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.lightOutlineVariant),
      ),
      child: ExpansionTile(
        shape: const Border(),
        title: Text(q,
            style:
                AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(a,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.lightOnSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}
