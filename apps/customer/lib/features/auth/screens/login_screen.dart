import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';
import 'package:url_launcher/url_launcher.dart';

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

  /// Accepts an email OR a South African cellphone number (auto-detected).
  String? _validateIdentifier(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your phone number or email';
    }
    return value.contains('@')
        ? Validators.requiredEmail(value)
        : Validators.phone(value);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final id = _identifierController.text.trim();
    final isEmail = id.contains('@');

    final ok = await ref.read(authActionProvider.notifier).login(
          identifier: id,
          password: _passwordController.text,
          isEmail: isEmail,
        );

    if (!mounted || ok) return;

    final err = ref.read(authActionProvider).error;
    if (err is AppException && err.code == 'account-not-found') {
      context.showErrorSnack('Account does not exist. Please register.');
    } else if (err is AppException && err.code == 'invalid-credentials') {
      context.showErrorSnack('Incorrect email/cellphone or password.');
    } else if (err is AppException && err.code == 'network-error') {
      context.showErrorSnack('Unable to connect. Please try again.');
    } else if (err is AppException) {
      context.showErrorSnack(err.message);
    } else {
      context.showErrorSnack('Sign in failed. Please try again.');
    }
  }

  Future<void> _whatsApp() async {
    final uri = Uri.parse('https://wa.me/27720000000');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _forgotPassword() {
    context.showSuccessSnack(
      'To reset your password, contact us on WhatsApp and we\'ll help you.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authActionProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.lightSurface,
      appBar: AppBar(
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: AppColors.lightSurface,
        elevation: 0,
        leading: BackButton(
          color: AppColors.lightOnSurface,
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(RouteConstants.welcome),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xl),

                Text(
                  'Welcome Back!',
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.lightOnSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Login to your SpazaLink account',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.lightOnSurfaceVariant,
                  ),
                ),

                const SizedBox(height: AppSpacing.x3l),

                SpazaTextField(
                  controller: _identifierController,
                  label: 'Email or Cellphone Number',
                  hint: 'Enter your email or cellphone',
                  prefixIcon: Icons.person_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateIdentifier,
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: AppSpacing.lg),

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

                const SizedBox(height: AppSpacing.sm),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.brandGreenPrimary,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                    ),
                    child: const Text('Forgot password?'),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                SpazaButton(
                  label: 'Login',
                  onPressed: isLoading ? null : _submit,
                  isLoading: isLoading,
                  variant: SpazaButtonVariant.primary,
                ),

                const SizedBox(height: AppSpacing.xl),

                // OR divider
                Row(
                  children: [
                    const Expanded(
                        child: Divider(color: AppColors.lightOutline)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      child: Text('OR',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.lightOnSurfaceVariant,
                          )),
                    ),
                    const Expanded(
                        child: Divider(color: AppColors.lightOutline)),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                SpazaButton(
                  label: 'Login with WhatsApp',
                  onPressed: _whatsApp,
                  variant: SpazaButtonVariant.outline,
                  leadingIcon: Icons.chat_rounded,
                ),

                const SizedBox(height: AppSpacing.xl),

                Center(
                  child: TextButton(
                    onPressed: () => context.go(RouteConstants.register),
                    child: RichText(
                      text: TextSpan(
                        style: AppTypography.bodyMedium,
                        children: [
                          const TextSpan(
                            text: "Don't have an account? ",
                            style:
                                TextStyle(color: AppColors.lightOnSurfaceVariant),
                          ),
                          const TextSpan(
                            text: 'Register',
                            style: TextStyle(
                              color: AppColors.brandGreenPrimary,
                              fontWeight: FontWeight.w700,
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
