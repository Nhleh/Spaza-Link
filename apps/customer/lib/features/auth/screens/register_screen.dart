import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

import '../providers/auth_provider.dart';

/// 3-step shop registration: (1) About You → (2) Your Shop → (3) Submit
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Step 1 controllers
  final _step1Key = GlobalKey<FormState>();
  final _ownerNameController = TextEditingController();

  // Step 2 controllers
  final _step2Key = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  String? _province;

  // Step 3 (optional GPS)
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

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
    _shopNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _nextPage() {
    final valid = switch (_currentPage) {
      0 => _step1Key.currentState?.validate() ?? false,
      1 => _step2Key.currentState?.validate() ?? false,
      _ => true,
    };
    if (!valid) return;

    if (_currentPage < 2) {
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
    final uid = ref.read(authUidProvider).valueOrNull;
    if (uid == null) return;

    GpsLocation? gps;
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    if (lat != null && lng != null) {
      gps = GpsLocation(latitude: lat, longitude: lng);
    }

    await ref.read(shopRegistrationProvider.notifier).register(
          ownerId: uid,
          ownerName: _ownerNameController.text.trim(),
          shopName: _shopNameController.text.trim(),
          physicalAddress: _addressController.text.trim(),
          city: _cityController.text.trim(),
          province: _province ?? '',
          gpsLocation: gps,
        );

    if (!mounted) return;
    final state = ref.read(shopRegistrationProvider);
    if (state.hasError) {
      context.showErrorSnack(
        (state.error is AppException)
            ? (state.error as AppException).message
            : 'Registration failed. Please try again.',
      );
    }
    // On success, router redirect fires and takes to pendingApproval.
  }

  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(shopRegistrationProvider);
    final isLoading = regState.isLoading;

    ref.listen(shopRegistrationProvider, (_, next) {
      if (next.hasError) {
        context.showErrorSnack(
          (next.error is AppException)
              ? (next.error as AppException).message
              : 'Registration failed.',
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: _currentPage > 0
            ? BackButton(onPressed: _prevPage)
            : BackButton(onPressed: () => context.go(RouteConstants.login)),
        title: Text('Register Your Shop'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentPage + 1) / 3,
            backgroundColor: AppColors.lightSurfaceVariant,
            valueColor: const AlwaysStoppedAnimation(AppColors.brandGreenPrimary),
            minHeight: 4,
          ),
        ),
      ),
      body: LoadingOverlay(
        isLoading: isLoading,
        message: 'Submitting…',
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _StepOne(
              formKey: _step1Key,
              ownerNameController: _ownerNameController,
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
            _StepThree(
              latController: _latController,
              lngController: _lngController,
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
            label: _currentPage < 2 ? 'Continue' : 'Submit Registration',
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
  });
  final GlobalKey<FormState> formKey;
  final TextEditingController ownerNameController;

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
              step: '1 of 3',
              title: 'About You',
              subtitle: 'Tell us about the shop owner.',
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
              textInputAction: TextInputAction.done,
            ),
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
              step: '2 of 3',
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

class _StepThree extends StatelessWidget {
  const _StepThree({
    required this.latController,
    required this.lngController,
  });
  final TextEditingController latController;
  final TextEditingController lngController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.x3l,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            step: '3 of 3',
            title: 'Location (Optional)',
            subtitle:
                'Adding your GPS coordinates helps us route deliveries faster. You can skip this for now.',
          ),

          const SizedBox(height: AppSpacing.x3l),

          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.brandGreenSurface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.brandGreenDark,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'You can also add your location from your shop profile after approval.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.brandGreenDark,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.x3l),

          SpazaTextField(
            controller: latController,
            label: 'Latitude (optional)',
            hint: 'e.g. -29.8587',
            prefixIcon: Icons.my_location_rounded,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
            ],
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: AppSpacing.lg),

          SpazaTextField(
            controller: lngController,
            label: 'Longitude (optional)',
            hint: 'e.g. 31.0218',
            prefixIcon: Icons.my_location_rounded,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
            ],
            textInputAction: TextInputAction.done,
          ),
        ],
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
