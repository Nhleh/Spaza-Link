import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';

import '../providers/admin_auth_provider.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(adminSignInProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final signInState = ref.watch(adminSignInProvider);
    final isLoading = signInState is AdminSignInLoading;

    ref.listen(adminSignInProvider, (_, next) {
      if (next is AdminSignInError) {
        context.showErrorSnack(next.message);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.adminDarkBackground,
      body: LoadingOverlay(
        isLoading: isLoading,
        message: 'Signing in…',
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Wordmark
                  RichText(
                    text: const TextSpan(children: [
                      TextSpan(
                        text: 'Spaza',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                          letterSpacing: -1.5,
                        ),
                      ),
                      TextSpan(
                        text: 'Link',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandGold,
                          letterSpacing: -1.5,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'ADMIN DASHBOARD',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.brandGold,
                      letterSpacing: 0.14,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.x4l),

                  // Login card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    decoration: BoxDecoration(
                      color: AppColors.adminDarkSurface,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(color: AppColors.adminDarkOutline),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Administrator Login',
                            style: AppTypography.headlineSmall.copyWith(
                              color: AppColors.darkOnSurface,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Sign in with your admin credentials.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.darkOnSurfaceVariant,
                            ),
                          ),

                          const SizedBox(height: AppSpacing.x3l),

                          // Email field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            style: TextStyle(color: AppColors.darkOnSurface),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(
                                  color: AppColors.darkOnSurfaceVariant),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: AppColors.darkOnSurfaceVariant,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd),
                                borderSide: BorderSide(
                                    color: AppColors.adminDarkOutline),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd),
                                borderSide: const BorderSide(
                                    color: AppColors.brandGold, width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd),
                                borderSide: const BorderSide(
                                    color: AppColors.error),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd),
                                borderSide: const BorderSide(
                                    color: AppColors.error, width: 2),
                              ),
                            ),
                            validator: Validators.requiredEmail,
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            style: TextStyle(color: AppColors.darkOnSurface),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(
                                  color: AppColors.darkOnSurfaceVariant),
                              prefixIcon: Icon(
                                Icons.lock_outlined,
                                color: AppColors.darkOnSurfaceVariant,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.darkOnSurfaceVariant,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd),
                                borderSide: BorderSide(
                                    color: AppColors.adminDarkOutline),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd),
                                borderSide: const BorderSide(
                                    color: AppColors.brandGold, width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd),
                                borderSide: const BorderSide(
                                    color: AppColors.error),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd),
                                borderSide: const BorderSide(
                                    color: AppColors.error, width: 2),
                              ),
                            ),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Password is required.' : null,
                          ),

                          const SizedBox(height: AppSpacing.x3l),

                          SpazaButton(
                            label: 'Sign In',
                            onPressed: isLoading ? null : _submit,
                            isLoading: isLoading,
                            variant: SpazaButtonVariant.primary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (AppConfig.instance.isDevelopment) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandGold.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        'DEV BUILD · ${AppConfig.instance.firebaseProjectId}',
                        style: AppTypography.labelSmall
                            .copyWith(color: AppColors.brandGold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
