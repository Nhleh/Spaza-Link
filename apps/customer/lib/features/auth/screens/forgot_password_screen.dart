import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

import '../providers/auth_provider.dart';

/// Step 1 — ask for the email and send a recovery code.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(_email.text);
      if (!mounted) return;
      context.showSuccessSnack('We\'ve emailed you a 6-digit code.');
      context.push(RouteConstants.resetPassword, extra: _email.text.trim());
    } on AppException catch (e) {
      if (mounted) context.showErrorSnack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                : context.go(RouteConstants.login)),
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
                Text('Reset your password',
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.lightOnSurface)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                    'Enter the email on your account and we\'ll send you a '
                    '6-digit code to reset your password.',
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
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _send(),
                ),
                const SizedBox(height: AppSpacing.xl),
                SpazaButton(
                  label: 'Send reset code',
                  onPressed: _busy ? null : _send,
                  isLoading: _busy,
                  variant: SpazaButtonVariant.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Step 2 — enter the emailed code + a new password.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});
  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).confirmPasswordReset(
            email: widget.email,
            token: _code.text,
            newPassword: _password.text,
          );
      if (!mounted) return;
      context.showSuccessSnack('Password updated. Please log in.');
      context.go(RouteConstants.login);
    } on AppException catch (e) {
      if (mounted) context.showErrorSnack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(widget.email);
      if (mounted) context.showSuccessSnack('A new code is on its way.');
    } on AppException catch (e) {
      if (mounted) context.showErrorSnack(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                : context.go(RouteConstants.login)),
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
                Text('Enter code & new password',
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.lightOnSurface)),
                const SizedBox(height: AppSpacing.xs),
                Text('We sent a 6-digit code to ${widget.email}.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.lightOnSurfaceVariant)),
                const SizedBox(height: AppSpacing.x3l),
                SpazaTextField(
                  controller: _code,
                  label: 'Reset code',
                  hint: '6-digit code',
                  prefixIcon: Icons.pin_rounded,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  validator: (v) =>
                      (v == null || v.trim().length < 6) ? 'Enter the 6-digit code' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.lg),
                SpazaTextField(
                  controller: _password,
                  label: 'New password',
                  hint: 'At least 6 characters',
                  prefixIcon: Icons.lock_rounded,
                  isPassword: true,
                  validator: Validators.password,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.lg),
                SpazaTextField(
                  controller: _confirm,
                  label: 'Confirm new password',
                  hint: 'Re-enter your new password',
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  validator: (v) =>
                      v != _password.text ? 'Passwords do not match' : null,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.xl),
                SpazaButton(
                  label: 'Update password',
                  onPressed: _busy ? null : _submit,
                  isLoading: _busy,
                  variant: SpazaButtonVariant.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: TextButton(
                    onPressed: _busy ? null : _resend,
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.brandGreenPrimary),
                    child: const Text('Didn\'t get it? Resend code'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
