import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

import '../../auth/providers/auth_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../orders/providers/order_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _streetCtrl = TextEditingController();
  final _suburbCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _paymentMethod = PaymentMethod.cod;

  @override
  void dispose() {
    _streetCtrl.dispose();
    _suburbCtrl.dispose();
    _cityCtrl.dispose();
    _postalCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopId = ref.watch(currentShopProvider).valueOrNull?.id ?? '';
    final uid = ref.watch(authUidProvider).valueOrNull ?? '';
    final subtotal = ref.watch(cartSubtotalProvider(shopId));
    final fee = ref.watch(cartDeliveryFeeProvider(shopId));
    final total = ref.watch(cartTotalProvider(shopId));
    final items = ref.watch(cartItemsProvider(shopId)).valueOrNull ?? [];
    final orderState = ref.watch(placeOrderProvider);
    final isLoading = orderState is PlaceOrderLoading;

    // Navigate away on success
    ref.listen<PlaceOrderState>(placeOrderProvider, (_, next) {
      if (next is PlaceOrderSuccess) {
        final orderId = next.order.id.isNotEmpty
            ? next.order.id
            : next.order.localUuid;
        // Replace current route so back doesn't return here
        context.go('/order-success/$orderId', extra: next.order);
      } else if (next is PlaceOrderError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.brandGreenPrimary,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Checkout',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
          children: [
            // ── Order summary ──────────────────────────────────────────────
            _SectionHeader(title: 'Order Summary'),
            const SizedBox(height: AppSpacing.md),
            _OrderSummaryCard(
              items: items,
              subtotal: subtotal,
              fee: fee,
              total: total,
            ),

            const SizedBox(height: AppSpacing.x3l),

            // ── Delivery address ───────────────────────────────────────────
            _SectionHeader(title: 'Delivery Address'),
            const SizedBox(height: AppSpacing.md),
            _AddressForm(
              streetCtrl: _streetCtrl,
              suburbCtrl: _suburbCtrl,
              cityCtrl: _cityCtrl,
              postalCtrl: _postalCtrl,
            ),

            const SizedBox(height: AppSpacing.x3l),

            // ── Delivery notes ─────────────────────────────────────────────
            _SectionHeader(title: 'Delivery Notes'),
            const SizedBox(height: AppSpacing.md),
            _NotesField(controller: _notesCtrl),

            const SizedBox(height: AppSpacing.x3l),

            // ── Payment method ─────────────────────────────────────────────
            _SectionHeader(title: 'Payment Method'),
            const SizedBox(height: AppSpacing.md),
            _PaymentMethodSelector(
              selected: _paymentMethod,
              onChanged: (m) => setState(() => _paymentMethod = m),
            ),

            const SizedBox(height: AppSpacing.x5l),

            // ── Place order button ─────────────────────────────────────────
            SizedBox(
              height: AppSpacing.buttonHeight,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () => _submit(shopId: shopId, uid: uid),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandGreenPrimary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Place Order — ${CurrencyFormatter.format(total)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),

            const SizedBox(height: AppSpacing.x3l),
          ],
        ),
      ),
    );
  }

  void _submit({required String shopId, required String uid}) {
    if (!_formKey.currentState!.validate()) return;

    final address = [
      _streetCtrl.text.trim(),
      _suburbCtrl.text.trim(),
      _cityCtrl.text.trim(),
      _postalCtrl.text.trim(),
    ].where((s) => s.isNotEmpty).join(', ');

    ref.read(placeOrderProvider.notifier).place(
          shopId: shopId,
          customerId: uid,
          deliveryAddress: address,
          paymentMethod: _paymentMethod,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.titleSmall.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.lightOnSurface,
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.items,
    required this.subtotal,
    required this.fee,
    required this.total,
  });

  final List<CartItemModel> items;
  final int subtotal;
  final int fee;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.lightOutlineVariant),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // Item count
          Row(
            children: [
              Text(
                '${items.length} item${items.length == 1 ? '' : 's'}',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.lightOnSurfaceVariant),
              ),
              const Spacer(),
              Text(
                CurrencyFormatter.format(subtotal),
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.lightOnSurface),
              ),
            ],
          ),

          // Item names
          const SizedBox(height: AppSpacing.xs),
          ...items.take(3).map((i) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    const SizedBox(width: AppSpacing.sm),
                    Text('• ', style: AppTypography.bodySmall),
                    Expanded(
                      child: Text(
                        '${i.productName} ×${i.quantity}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.lightOnSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
          if (items.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: AppSpacing.sm),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '+ ${items.length - 3} more',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.lightOnSurfaceVariant,
                  ),
                ),
              ),
            ),

          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.lightOutlineVariant),
          const SizedBox(height: AppSpacing.md),

          // Delivery
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Delivery',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.lightOnSurfaceVariant)),
              Text(
                CurrencyFormatter.formatDeliveryFee(fee),
                style: AppTypography.bodyMedium.copyWith(
                  color: fee == 0
                      ? AppColors.brandGreenPrimary
                      : AppColors.lightOnSurface,
                  fontWeight: fee == 0 ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                CurrencyFormatter.format(total),
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandGreenPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressForm extends StatelessWidget {
  const _AddressForm({
    required this.streetCtrl,
    required this.suburbCtrl,
    required this.cityCtrl,
    required this.postalCtrl,
  });

  final TextEditingController streetCtrl;
  final TextEditingController suburbCtrl;
  final TextEditingController cityCtrl;
  final TextEditingController postalCtrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Field(
          controller: streetCtrl,
          label: 'Street address',
          hint: '123 Main Street',
          required: true,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _Field(
                controller: suburbCtrl,
                label: 'Suburb',
                hint: 'Soweto',
                required: true,
                textCapitalization: TextCapitalization.words,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _Field(
                controller: cityCtrl,
                label: 'City',
                hint: 'Johannesburg',
                required: true,
                textCapitalization: TextCapitalization.words,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: 140,
          child: _Field(
            controller: postalCtrl,
            label: 'Postal code',
            hint: '1804',
            required: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.required = false,
    this.keyboardType,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool required;
  final TextInputType? keyboardType;
  final int? maxLength;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.lightOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.lightOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(
              color: AppColors.brandGreenPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide:
              const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide:
              const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }
}

class _NotesField extends StatelessWidget {
  const _NotesField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: 'e.g. gate code, landmark, delivery instructions…',
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.lightOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.lightOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(
              color: AppColors.brandGreenPrimary, width: 2),
        ),
      ),
    );
  }
}

class _PaymentMethodSelector extends StatelessWidget {
  const _PaymentMethodSelector({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  static const _methods = [
    _PaymentOption(
      id: PaymentMethod.cod,
      label: 'Cash on Delivery',
      subtitle: 'Pay when your order arrives',
      icon: Icons.payments_outlined,
      available: true,
    ),
    _PaymentOption(
      id: PaymentMethod.payfast,
      label: 'PayFast',
      subtitle: 'Coming soon',
      icon: Icons.credit_card_outlined,
      available: false,
    ),
    _PaymentOption(
      id: PaymentMethod.ozow,
      label: 'Ozow EFT',
      subtitle: 'Coming soon',
      icon: Icons.account_balance_outlined,
      available: false,
    ),
    _PaymentOption(
      id: PaymentMethod.yoco,
      label: 'Yoco Card',
      subtitle: 'Coming soon',
      icon: Icons.tap_and_play_outlined,
      available: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _methods
          .map((opt) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _PaymentTile(
                  option: opt,
                  isSelected: selected == opt.id,
                  onTap: opt.available ? () => onChanged(opt.id) : null,
                ),
              ))
          .toList(),
    );
  }
}

class _PaymentOption {
  const _PaymentOption({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.available,
  });

  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final bool available;
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _PaymentOption option;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dimmed = !option.available;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected
                ? AppColors.brandGreenPrimary
                : AppColors.lightOutline,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(
              option.icon,
              size: 22,
              color: dimmed
                  ? AppColors.lightOnSurfaceVariant.withValues(alpha: 0.4)
                  : isSelected
                      ? AppColors.brandGreenPrimary
                      : AppColors.lightOnSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: dimmed
                          ? AppColors.lightOnSurfaceVariant
                              .withValues(alpha: 0.4)
                          : AppColors.lightOnSurface,
                    ),
                  ),
                  Text(
                    option.subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: dimmed
                          ? AppColors.lightOnSurfaceVariant
                              .withValues(alpha: 0.4)
                          : AppColors.lightOnSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.brandGreenPrimary,
                size: 20,
              )
            else if (dimmed)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lightSurfaceVariant,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  'Soon',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.lightOnSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
