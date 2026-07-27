import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Accepts an email OR a South African cellphone number.
  String? _validateIdentifier(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your email or cellphone number';
    }
    // If it looks like an email, validate as email; otherwise as a phone.
    return value.contains('@')
        ? Validators.requiredEmail(value)
        : Validators.phone(value);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final id = _identifierController.text.trim();
    // Auto-detect: an '@' means email, otherwise treat it as a cellphone.
    final isEmail = id.contains('@');

    final ok = await ref.read(authActionProvider.notifier).login(
          identifier: id,
          password: _passwordController.text,
          isEmail: isEmail,
        );

    if (!mounted || ok) return;

    // Failed — inspect the error to decide messaging / navigation.
    final err = ref.read(authActionProvider).error;
    if (err is AppException && err.code == 'account-not-found') {
      context.showErrorSnack('No account found. Please register first.');
      context.go(RouteConstants.register);
    } else if (err is AppException) {
      context.showErrorSnack(err.message);
    } else {
      context.showErrorSnack('Sign in failed. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authActionProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(RouteConstants.welcome)),
        title: const Text('Login'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.x3l),

                Text('Welcome back', style: AppTypography.headlineMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Sign in with your email or cellphone number.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.lightOnSurfaceVariant,
                  ),
                ),

                const SizedBox(height: AppSpacing.x3l),

                // Single field — accepts either email or cellphone.
                SpazaTextField(
                  controller: _identifierController,
                  label: 'Email or cellphone number',
                  hint: 'you@example.com  or  082 123 4567',
                  prefixIcon: Icons.person_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateIdentifier,
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: AppSpacing.lg),

                // Password
                SpazaTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  prefixIcon: Icons.lock_rounded,
                  isPassword: true,
                  validator: Validators.password,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                ),

                const SizedBox(height: AppSpacing.xxl),

                SpazaButton(
                  label: 'Login',
                  onPressed: isLoading ? null : _submit,
                  isLoading: isLoading,
                  variant: SpazaButtonVariant.primary,
                ),

                const SizedBox(height: AppSpacing.xl),

                Center(
                  child: TextButton(
                    onPressed: () => context.go(RouteConstants.register),
                    child: RichText(
                      text: TextSpan(
                        style: AppTypography.bodyMedium,
                        children: [
                          TextSpan(
                            text: 'New to SpazaLink? ',
                            style: TextStyle(
                              color: AppColors.lightOnSurfaceVariant,
                            ),
                          ),
                          const TextSpan(
                            text: 'Register your shop',
                            style: TextStyle(
                              color: AppColors.brandGreenPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
