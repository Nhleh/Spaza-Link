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
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final raw = _phoneController.text.trim();
    // Normalise to E.164: 0821234567 → +27821234567
    final phone = raw.startsWith('0')
        ? '+27${raw.substring(1)}'
        : raw.startsWith('+27')
            ? raw
            : '+27$raw';

    await ref.read(otpFlowProvider.notifier).sendOtp(phone);

    if (!mounted) return;
    final state = ref.read(otpFlowProvider);
    if (state is OtpFlowCodeSent) {
      context.go(
        RouteConstants.otpVerify,
        extra: {'phone': phone},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final otpState = ref.watch(otpFlowProvider);
    final isLoading = otpState is OtpFlowSending;

    ref.listen(otpFlowProvider, (_, next) {
      if (next is OtpFlowError) {
        context.showErrorSnack(next.message);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.x4l),

                // Brand wordmark
                RichText(
                  text: const TextSpan(children: [
                    TextSpan(
                      text: 'Spaza',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandGreenDark,
                        letterSpacing: -1.0,
                      ),
                    ),
                    TextSpan(
                      text: 'Link',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandGold,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  AppConstants.appTagline,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.lightOnSurfaceVariant,
                  ),
                ),

                const SizedBox(height: AppSpacing.x4l),

                Text('Welcome back', style: AppTypography.headlineMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Enter your South African mobile number to sign in.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.lightOnSurfaceVariant,
                  ),
                ),

                const SizedBox(height: AppSpacing.x3l),

                SpazaTextField(
                  controller: _phoneController,
                  label: 'Mobile number',
                  hint: '082 123 4567',
                  prefixIcon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                ),

                const SizedBox(height: AppSpacing.xxl),

                SpazaButton(
                  label: 'Send OTP',
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
