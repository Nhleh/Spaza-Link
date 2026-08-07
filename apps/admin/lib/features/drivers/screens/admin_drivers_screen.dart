import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';

import '../data/admin_drivers_repository.dart';
import '../providers/admin_drivers_provider.dart';

/// Driver account management (create + list). Delivery assignment happens from
/// the order detail screen.
class AdminDriversScreen extends ConsumerWidget {
  const AdminDriversScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminDriversProvider);

    return Scaffold(
      backgroundColor: AppColors.adminDarkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.adminDarkSurface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Drivers',
            style: TextStyle(
                color: AppColors.darkOnSurface, fontWeight: FontWeight.w700)),
        actions: [
          FilledButton.icon(
            onPressed: () => _openCreate(context, ref),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Add Driver'),
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
              const Text('Failed to load drivers',
                  style: TextStyle(color: AppColors.darkOnSurface)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(adminDriversProvider),
                child: const Text('Retry',
                    style: TextStyle(color: AppColors.brandGreenPrimary)),
              ),
            ],
          ),
        ),
        data: (drivers) {
          if (drivers.isEmpty) {
            return const Center(
              child: Text(
                'No drivers yet.\nAdd one to start assigning deliveries.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.darkOnSurfaceVariant),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: drivers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _DriverRow(driver: drivers[i]),
          );
        },
      ),
    );
  }

  Future<void> _openCreate(BuildContext context, WidgetRef ref) async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const _CreateDriverDialog(),
    );
    if (created == true) ref.invalidate(adminDriversProvider);
  }
}

class _DriverRow extends StatelessWidget {
  const _DriverRow({required this.driver});
  final DriverInfo driver;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.adminDarkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkOutline),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.brandGreenPrimary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.delivery_dining_rounded,
                color: AppColors.brandGreenPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(driver.name,
                    style: const TextStyle(
                        color: AppColors.darkOnSurface,
                        fontWeight: FontWeight.w700)),
                if (driver.phone.isNotEmpty)
                  Text(driver.phone,
                      style: const TextStyle(
                          color: AppColors.darkOnSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateDriverDialog extends ConsumerStatefulWidget {
  const _CreateDriverDialog();
  @override
  ConsumerState<_CreateDriverDialog> createState() =>
      _CreateDriverDialogState();
}

class _CreateDriverDialogState extends ConsumerState<_CreateDriverDialog> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _password.text.trim().length < 6) {
      _snack('Enter a name, email and a password of at least 6 characters.',
          error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(adminDriversRepositoryProvider).createDriver(
            email: _email.text,
            password: _password.text,
            name: _name.text,
            phone: _phone.text,
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Could not create driver: $e', error: true);
    }
  }

  void _snack(String m, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m),
        backgroundColor: error ? AppColors.error : AppColors.brandGreenPrimary,
      ));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.adminDarkSurface,
      title: const Text('New driver',
          style: TextStyle(color: AppColors.darkOnSurface)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(_name, 'Full name'),
            const SizedBox(height: 10),
            _field(_email, 'Email (used to log in)'),
            const SizedBox(height: 10),
            _field(_phone, 'Phone (optional)'),
            const SizedBox(height: 10),
            _field(_password, 'Temporary password (min 6)'),
            const SizedBox(height: 6),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'The driver logs into the Driver app with this email + password.',
                style: TextStyle(
                    color: AppColors.darkOnSurfaceVariant, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandGreenPrimary),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.white))
              : const Text('Create driver'),
        ),
      ],
    );
  }

  Widget _field(TextEditingController c, String label) => TextField(
        controller: c,
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
