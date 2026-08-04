import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

import '../providers/auth_provider.dart';

/// 2-step shop registration: (1) Your Account → (2) Your Shop → Submit.
///
/// Step 1 creates the sign-in account (name, email, cellphone, password — sign
/// in with email OR cellphone). Step 2 captures shop details; the shop's
/// location is taken from the physical address — no manual GPS.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Step 1 — account
  final _step1Key = GlobalKey<FormState>();
  final _ownerNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _useEmail = true;

  // Step 2 — shop
  final _step2Key = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  String? _province;

  static const _provinces = [
    'Eastern Cape',
    'Free State',
    'Gauteng',
    'KwaZulu-Natal',
    'Limpopo',
    'Mpumalanga',
    'North West',
    'Northern Cape',
    'Western Cape',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _shopNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _nextPage() {
    final valid = switch (_currentPage) {
      0 => _step1Key.currentState?.validate() ?? false,
      1 => _step2Key.currentState?.validate() ?? false,
      _ => true,
    };
    if (!valid) return;

    if (_currentPage < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    } else {
      _submit();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    }
  }

  Future<void> _submit() async {
    final ok = await ref.read(authActionProvider.notifier).registerAccountAndShop(
          name: _ownerNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          useEmailLogin: _useEmail,
          shopName: _shopNameController.text.trim(),
          physicalAddress: _addressController.text.trim(),
          city: _cityController.text.trim(),
          province: _province ?? '',
        );

    if (!mounted || ok) return;
    // On success the router redirect takes over (→ pending approval).
    final err = ref.read(authActionProvider).error;
    context.showErrorSnack(
      (err is AppException) ? err.message : 'Registration failed. Please try again.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authActionProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        leading: _currentPage > 0
            ? BackButton(onPressed: _prevPage)
            : BackButton(onPressed: () => context.go(RouteConstants.welcome)),
        title: const Text('Register Your Shop'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentPage + 1) / 2,
            backgroundColor: AppColors.lightSurfaceVariant,
            valueColor: const AlwaysStoppedAnimation(AppColors.brandGreenPrimary),
            minHeight: 4,
          ),
        ),
      ),
      body: LoadingOverlay(
        isLoading: isLoading,
        message: 'Creating your account…',
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _StepOne(
              formKey: _step1Key,
              ownerNameController: _ownerNameController,
              emailController: _emailController,
              phoneController: _phoneController,
              passwordController: _passwordController,
              useEmail: _useEmail,
              onLoginMethodChanged: (v) => setState(() => _useEmail = v),
            ),
            _StepTwo(
              formKey: _step2Key,
              shopNameController: _shopNameController,
              addressController: _addressController,
              cityController: _cityController,
              province: _province,
              provinces: _provinces,
              onProvinceChanged: (v) => setState(() => _province = v),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.md,
            AppSpacing.xxl,
            AppSpacing.xl,
          ),
          child: SpazaButton(
            label: _currentPage < 1 ? 'Continue' : 'Submit Registration',
            onPressed: isLoading ? null : _nextPage,
            isLoading: isLoading,
            variant: SpazaButtonVariant.primary,
          ),
        ),
      ),
    );
  }
}

// ── Step widgets ──────────────────────────────────────────────────────────────

class _StepOne extends StatelessWidget {
  const _StepOne({
    required this.formKey,
    required this.ownerNameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.useEmail,
    required this.onLoginMethodChanged,
  });
  final GlobalKey<FormState> formKey;
  final TextEditingController ownerNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final bool useEmail;
  final ValueChanged<bool> onLoginMethodChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.x3l,
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepHeader(
              step: '1 of 2',
              title: 'Your Account',
              subtitle: 'Create your sign-in details.',
            ),
            const SizedBox(height: AppSpacing.x3l),

            SpazaTextField(
              controller: ownerNameController,
              label: 'Full Name',
              hint: 'e.g. Sipho Dlamini',
              prefixIcon: Icons.person_rounded,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              validator: Validators.ownerName,
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: AppSpacing.lg),

            SpazaTextField(
              controller: emailController,
              label: 'Email',
              hint: 'you@example.com',
              prefixIcon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.requiredEmail,
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: AppSpacing.lg),

            SpazaTextField(
              controller: phoneController,
              label: 'Cellphone number',
              hint: '082 123 4567',
              prefixIcon: Icons.phone_android_rounded,
              keyboardType: TextInputType.phone,
              validator: Validators.phone,
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: AppSpacing.lg),

            SpazaTextField(
              controller: passwordController,
              label: 'Password',
              hint: 'At least 8 characters',
              prefixIcon: Icons.lock_rounded,
              isPassword: true,
              validator: Validators.password,
              textInputAction: TextInputAction.done,
            ),
            // You can sign in later with EITHER your email or cellphone — the
            // login screen auto-detects, so there's no method to choose here.
          ],
        ),
      ),
    );
  }
}

class _StepTwo extends StatelessWidget {
  const _StepTwo({
    required this.formKey,
    required this.shopNameController,
    required this.addressController,
    required this.cityController,
    required this.province,
    required this.provinces,
    required this.onProvinceChanged,
  });
  final GlobalKey<FormState> formKey;
  final TextEditingController shopNameController;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final String? province;
  final List<String> provinces;
  final ValueChanged<String?> onProvinceChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.x3l,
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepHeader(
              step: '2 of 2',
              title: 'Your Shop',
              subtitle: 'Where is your shop located?',
            ),
            const SizedBox(height: AppSpacing.x3l),

            SpazaTextField(
              controller: shopNameController,
              label: 'Shop Name',
              hint: 'e.g. Sipho\'s General Store',
              prefixIcon: Icons.store_rounded,
              textCapitalization: TextCapitalization.words,
              validator: Validators.shopName,
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: AppSpacing.lg),

            SpazaTextField(
              controller: addressController,
              label: 'Physical Address',
              hint: 'e.g. 12 Main Street, Umlazi',
              prefixIcon: Icons.location_on_rounded,
              textCapitalization: TextCapitalization.words,
              validator: Validators.address,
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: AppSpacing.lg),

            SpazaTextField(
              controller: cityController,
              label: 'City / Town',
              hint: 'e.g. Durban',
              prefixIcon: Icons.location_city_rounded,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'City is required.' : null,
              textInputAction: TextInputAction.done,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Province dropdown
            DropdownButtonFormField<String>(
              value: province, // ignore: deprecated_member_use
              decoration: InputDecoration(
                labelText: 'Province *',
                prefixIcon: const Icon(Icons.map_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
              items: provinces
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: onProvinceChanged,
              validator: (v) => v == null ? 'Please select a province.' : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.step,
    required this.title,
    required this.subtitle,
  });
  final String step;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STEP $step',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.brandGreenPrimary,
            letterSpacing: 0.1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(title, style: AppTypography.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.lightOnSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
