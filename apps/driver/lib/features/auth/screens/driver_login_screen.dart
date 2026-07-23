import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

import '../providers/driver_auth_provider.dart';

class DriverLoginScreen extends ConsumerStatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  ConsumerState<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends ConsumerState<DriverLoginScreen> {
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
    final phone = raw.startsWith('0')
        ? '+27${raw.substring(1)}'
        : raw.startsWith('+27')
            ? raw
            : '+27$raw';

    await ref.read(driverOtpFlowProvider.notifier).sendOtp(phone);

    if (!mounted) return;
    final state = ref.read(driverOtpFlowProvider);
    if (state is DriverOtpFlowCodeSent) {
      context.go(RouteConstants.driverOtpVerify, extra: {'phone': phone});
    }
  }

  @override
  Widget build(BuildContext context) {
    final otpState = ref.watch(driverOtpFlowProvider);
    final isLoading = otpState is DriverOtpFlowSending;

    ref.listen(driverOtpFlowProvider, (_, next) {
      if (next is DriverOtpFlowError) {
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

                // Wordmark
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
                  'DRIVER',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.lightOnSurfaceVariant,
                    letterSpacing: 0.12,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: AppSpacing.x4l),

                Text('Welcome, Driver', style: AppTypography.headlineMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Enter your registered South African mobile number.',
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
                  child: Text(
                    'Only registered SpazaLink drivers can sign in.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.lightOnSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
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
