import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spazalink_core/core.dart';

import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopName = TextEditingController();
  final _ownerName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _location = TextEditingController();

  Uint8List? _photoBytes;
  String _photoExt = 'jpg';

  @override
  void dispose() {
    _shopName.dispose();
    _ownerName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 900,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _photoBytes = bytes;
      _photoExt = file.name.contains('.') ? file.name.split('.').last : 'jpg';
    });
  }

  String? _required(String? v, String field) =>
      (v == null || v.trim().isEmpty) ? 'Enter your $field' : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await ref.read(authActionProvider.notifier).registerAccountAndShop(
          name: _ownerName.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          password: _password.text,
          useEmailLogin: true,
          shopName: _shopName.text.trim(),
          physicalAddress: _location.text.trim(),
          city: '',
          province: '',
          shopPhotoBytes: _photoBytes,
          shopPhotoExt: _photoExt,
        );

    if (!mounted || ok) return;
    final err = ref.read(authActionProvider).error;
    if (err is AppException && err.code == 'phone-already-in-use') {
      context.showErrorSnack('An account already exists.');
    } else if (err is AppException && err.code == 'network-error') {
      context.showErrorSnack('Unable to connect. Please try again.');
    } else {
      context.showErrorSnack((err is AppException)
          ? err.message
          : 'Registration failed. Please try again.');
    }
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
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Create Your Account',
                  style: AppTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.lightOnSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  "Let's get your spaza shop on SpazaLink",
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.lightOnSurfaceVariant,
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Shop photo upload
                Center(child: _PhotoPicker(bytes: _photoBytes, onTap: _pickPhoto)),

                const SizedBox(height: AppSpacing.xl),

                SpazaTextField(
                  controller: _shopName,
                  label: 'Shop Name',
                  hint: 'Enter shop name',
                  prefixIcon: Icons.storefront_rounded,
                  validator: (v) => _required(v, 'shop name'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.lg),
                SpazaTextField(
                  controller: _ownerName,
                  label: 'Owner Name',
                  hint: 'Enter owner name',
                  prefixIcon: Icons.person_rounded,
                  textCapitalization: TextCapitalization.words,
                  validator: Validators.ownerName,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.lg),
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
                  controller: _phone,
                  label: 'Cellphone Number',
                  hint: 'Enter phone number',
                  prefixIcon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.lg),
                SpazaTextField(
                  controller: _password,
                  label: 'Password',
                  hint: 'Create a password',
                  prefixIcon: Icons.lock_rounded,
                  isPassword: true,
                  validator: Validators.password,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.lg),
                SpazaTextField(
                  controller: _location,
                  label: 'Location',
                  hint: 'Your shop location',
                  prefixIcon: Icons.location_on_rounded,
                  validator: (v) => _required(v, 'location'),
                  textInputAction: TextInputAction.done,
                ),

                const SizedBox(height: AppSpacing.xxl),

                SpazaButton(
                  label: 'Register',
                  onPressed: isLoading ? null : _submit,
                  isLoading: isLoading,
                  variant: SpazaButtonVariant.primary,
                ),

                const SizedBox(height: AppSpacing.lg),

                Center(
                  child: TextButton(
                    onPressed: () => context.go(RouteConstants.login),
                    child: RichText(
                      text: TextSpan(
                        style: AppTypography.bodyMedium,
                        children: [
                          const TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(
                                color: AppColors.lightOnSurfaceVariant),
                          ),
                          const TextSpan(
                            text: 'Login',
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

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.bytes, required this.onTap});
  final Uint8List? bytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: AppColors.brandGreenSurface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.lightOutlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: bytes != null
                ? Image.memory(bytes!, fit: BoxFit.cover)
                : const Icon(Icons.storefront_rounded,
                    color: AppColors.brandGreenPrimary, size: 40),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            bytes != null ? 'Change Shop Photo' : 'Upload Shop Photo',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.brandGreenPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
