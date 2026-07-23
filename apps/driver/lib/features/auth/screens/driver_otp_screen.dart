import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

import '../providers/driver_auth_provider.dart';

class DriverOtpScreen extends ConsumerStatefulWidget {
  const DriverOtpScreen({super.key, required this.phoneNumber});
  final String phoneNumber;

  @override
  ConsumerState<DriverOtpScreen> createState() => _DriverOtpScreenState();
}

class _DriverOtpScreenState extends ConsumerState<DriverOtpScreen> {
  static const _otpLength = 6;
  static const _resendSeconds = 60;

  final _controllers = List.generate(_otpLength, (_) => TextEditingController());
  final _focusNodes = List.generate(_otpLength, (_) => FocusNode());

  int _secondsLeft = _resendSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  String get _currentOtp => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.isEmpty) {
      if (index > 0) _focusNodes[index - 1].requestFocus();
      return;
    }
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < _otpLength && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      final nextFocus = (digits.length < _otpLength) ? digits.length : _otpLength - 1;
      _focusNodes[nextFocus].requestFocus();
      if (digits.length == _otpLength) _submit();
      return;
    }
    if (index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
      _submit();
    }
  }

  Future<void> _submit() async {
    final otp = _currentOtp;
    if (otp.length != _otpLength) return;

    final success = await ref.read(driverOtpFlowProvider.notifier).verifyOtp(otp);
    if (!mounted) return;

    if (success) {
      context.go(RouteConstants.driverDeliveries);
    }
  }

  Future<void> _resend() async {
    for (final c in _controllers) c.clear();
    _focusNodes.first.requestFocus();
    await ref.read(driverOtpFlowProvider.notifier).resendOtp();
    _startCountdown();
  }

  @override
  Widget build(BuildContext context) {
    final otpState = ref.watch(driverOtpFlowProvider);
    final isLoading = otpState is DriverOtpFlowVerifying;

    ref.listen(driverOtpFlowProvider, (_, next) {
      if (next is DriverOtpFlowError) {
        context.showErrorSnack(next.message);
        for (final c in _controllers) c.clear();
        _focusNodes.first.requestFocus();
      }
    });

    final maskedPhone = widget.phoneNumber.replaceRange(
      3,
      widget.phoneNumber.length - 3,
      '•' * (widget.phoneNumber.length - 6),
    );

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.go(RouteConstants.driverLogin),
        ),
        title: const Text('Verify your number'),
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: isLoading,
        message: 'Verifying…',
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.x3l),

                Text('Enter the 6-digit code',
                    style: AppTypography.headlineMedium),
                const SizedBox(height: AppSpacing.xs),
                RichText(
                  text: TextSpan(
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.lightOnSurfaceVariant,
                    ),
                    children: [
                      const TextSpan(text: 'We sent it to '),
                      TextSpan(
                        text: maskedPhone,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.lightOnSurface,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.x3l),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_otpLength, (i) {
                    return SizedBox(
                      width: 48,
                      child: TextFormField(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: i == 0 ? _otpLength : 1,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: AppTypography.headlineSmall,
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: AppColors.lightSurfaceVariant,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                            borderSide:
                                const BorderSide(color: AppColors.lightOutline),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                            borderSide: const BorderSide(
                              color: AppColors.brandGreenPrimary,
                              width: 2,
                            ),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onChanged: (v) => _onDigitChanged(i, v),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: AppSpacing.x3l),

                SpazaButton(
                  label: 'Verify',
                  onPressed: isLoading ? null : _submit,
                  isLoading: isLoading,
                  variant: SpazaButtonVariant.primary,
                ),

                const SizedBox(height: AppSpacing.xl),

                Center(
                  child: _secondsLeft > 0
                      ? Text(
                          'Resend code in ${_secondsLeft}s',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.lightOnSurfaceVariant,
                          ),
                        )
                      : TextButton(
                          onPressed: _resend,
                          child: const Text(
                            'Resend OTP',
                            style:
                                TextStyle(color: AppColors.brandGreenPrimary),
                          ),
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
