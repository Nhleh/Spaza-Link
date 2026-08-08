import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';

import '../providers/driver_auth_provider.dart';

/// Driver login — email + password (accounts are created by the admin).
class DriverLoginScreen extends ConsumerStatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  ConsumerState<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends ConsumerState<DriverLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final repo = ref.read(driverAuthRepositoryProvider);
    try {
      await repo.signInWithIdentifier(
        identifier: _email.text.trim(),
        password: _password.text,
        isEmail: true,
      );
      // Must be a driver account.
      final uid = ref.read(driverAuthUidProvider).valueOrNull;
      final user = uid == null ? null : await repo.getUser(uid);
      if (user?.role != 'driver') {
        await repo.signOut();
        if (!mounted) return;
        setState(() => _loading = false);
        _error('This app is for drivers only. Ask the admin for a driver account.');
        return;
      }
      // Success — the router redirect forwards to Deliveries.
      if (mounted) setState(() => _loading = false);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _error(e.code == 'invalid-credentials'
          ? 'Incorrect email or password.'
          : e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _error('Could not sign in. Please try again.');
    }
  }

  void _error(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m), backgroundColor: AppColors.error));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightSurface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.x4l),
                const Icon(Icons.delivery_dining_rounded,
                    size: 56, color: AppColors.brandGreenPrimary),
                const SizedBox(height: AppSpacing.md),
                Text('SpazaLink Driver',
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.lightOnSurface)),
                const SizedBox(height: 4),
                Text('Sign in to see your deliveries',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.lightOnSurfaceVariant)),
                const SizedBox(height: AppSpacing.x3l),
                SpazaTextField(
                  controller: _email,
                  label: 'Email',
                  hint: 'you@example.com',
                  prefixIcon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.requiredEmail,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.lg),
                SpazaTextField(
                  controller: _password,
                  label: 'Password',
                  hint: 'Your password',
                  prefixIcon: Icons.lock_rounded,
                  isPassword: true,
                  validator: Validators.password,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.xl),
                SpazaButton(
                  label: 'Login',
                  onPressed: _loading ? null : _submit,
                  isLoading: _loading,
                  variant: SpazaButtonVariant.primary,
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
