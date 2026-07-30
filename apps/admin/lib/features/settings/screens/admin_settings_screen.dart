import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';

import '../../auth/providers/admin_auth_provider.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(adminCurrentUserProvider);
    final user = userAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.adminDarkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.adminDarkSurface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Settings',
            style: TextStyle(
                color: AppColors.darkOnSurface, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _section('Admin account', [
            _kv('Email', user?.email ?? '—'),
            _kv('Role', (user?.role ?? 'admin').toUpperCase()),
            _kv('Status', (user?.isActive ?? true) ? 'Active' : 'Disabled'),
          ]),
          const SizedBox(height: 16),
          _section('Business rules', [
            _kv('Minimum order',
                CurrencyFormatter.format(AppConstants.minOrderCents)),
            _kv('Delivery fee',
                CurrencyFormatter.format(AppConstants.deliveryFeeCents)),
            _kv('Free delivery over',
                CurrencyFormatter.format(
                    AppConstants.freeDeliveryThresholdCents)),
          ]),
          const SizedBox(height: 16),
          _section('System', [
            _kv('Backend', 'Supabase (cloud)'),
            _kv('Environment',
                AppConfig.instance.isDevelopment ? 'Development' : 'Production'),
          ]),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _confirmSignOut(context, ref),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign out'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error.withValues(alpha: 0.15),
                foregroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.adminDarkSurface,
        title: const Text('Sign out?',
            style: TextStyle(color: AppColors.darkOnSurface)),
        content: const Text('You will need to log in again.',
            style: TextStyle(color: AppColors.darkOnSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.darkOnSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      // The router redirect sends the signed-out admin back to the login screen.
      await adminSignOut(ref);
    }
  }

  Widget _section(String title, List<Widget> rows) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.adminDarkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.adminDarkOutline, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.toUpperCase(),
                style: const TextStyle(
                    color: AppColors.darkOnSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6)),
            const SizedBox(height: 14),
            ...rows,
          ],
        ),
      );

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 160,
              child: Text(k,
                  style: const TextStyle(
                      color: AppColors.darkOnSurfaceVariant, fontSize: 12.5)),
            ),
            Expanded(
              child: Text(v,
                  style: const TextStyle(
                      color: AppColors.darkOnSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );
}
