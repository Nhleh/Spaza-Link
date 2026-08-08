import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:signature/signature.dart';
import 'package:spazalink_core/core.dart';

import '../models/delivery.dart';
import '../providers/delivery_provider.dart';

class CompleteDeliveryScreen extends ConsumerStatefulWidget {
  const CompleteDeliveryScreen({super.key, required this.delivery});
  final Delivery delivery;

  @override
  ConsumerState<CompleteDeliveryScreen> createState() =>
      _CompleteDeliveryScreenState();
}

class _CompleteDeliveryScreenState
    extends ConsumerState<CompleteDeliveryScreen> {
  late final SignatureController _sig;
  late final TextEditingController _receivedBy;
  bool _cashCollected = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _sig = SignatureController(
      penStrokeWidth: 3,
      penColor: AppColors.lightOnSurface,
      exportBackgroundColor: AppColors.white,
    );
    _receivedBy =
        TextEditingController(text: widget.delivery.customerName);
  }

  @override
  void dispose() {
    _sig.dispose();
    _receivedBy.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_receivedBy.text.trim().isEmpty) {
      _snack('Enter the name of the person who received the order.');
      return;
    }
    if (_sig.isEmpty) {
      _snack('Please ask the customer to sign first.');
      return;
    }
    if (widget.delivery.isCod && !_cashCollected) {
      _snack('Confirm the cash was collected to complete this delivery.');
      return;
    }
    setState(() => _busy = true);
    try {
      final repo = ref.read(driverDeliveryRepositoryProvider);
      // Re-fetch so the invoice has the freshest item detail.
      final d = await repo.getDelivery(widget.delivery.orderId) ?? widget.delivery;
      final sigPng = await _sig.toPngBytes();
      if (sigPng == null) throw Exception('Could not read the signature.');
      final slipPng = await _buildSlip(d, sigPng, _receivedBy.text.trim());

      await repo.completeDelivery(
            orderId: d.orderId,
            signaturePng: sigPng,
            slipPng: slipPng,
            cashCollected: _cashCollected,
            paymentMethod: d.paymentMethod,
          );

      ref.invalidate(myDeliveriesProvider);
      ref.invalidate(deliveryDetailProvider(d.orderId));
      if (!mounted) return;
      // Back to the deliveries list.
      context.go(RouteConstants.driverDeliveries);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Delivery completed ✅'),
        backgroundColor: AppColors.brandGreenPrimary,
      ));
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        _snack('Could not complete delivery: $e');
      }
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m), backgroundColor: AppColors.error));

  @override
  Widget build(BuildContext context) {
    final d = widget.delivery;
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.brandGreenPrimary,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: const Text('Complete delivery',
            style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Order #${d.ref} • ${CurrencyFormatter.format(d.totalCents)}',
              style: AppTypography.titleSmall
                  .copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.md),

          Text('Received by (customer name)',
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.lightOnSurfaceVariant)),
          const SizedBox(height: 6),
          TextField(
            controller: _receivedBy,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Full name of the person who received the order',
              prefixIcon: const Icon(Icons.person_rounded, size: 20),
              filled: true,
              fillColor: AppColors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide:
                    const BorderSide(color: AppColors.lightOutlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide:
                    const BorderSide(color: AppColors.brandGreenPrimary),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('Customer signature',
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.lightOnSurfaceVariant)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.lightOutlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: Signature(
              controller: _sig,
              height: 220,
              backgroundColor: AppColors.white,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _sig.clear(),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Clear'),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.lightOnSurfaceVariant),
            ),
          ),

          if (d.isCod) ...[
            const SizedBox(height: AppSpacing.sm),
            CheckboxListTile(
              value: _cashCollected,
              onChanged: (v) => setState(() => _cashCollected = v ?? false),
              activeColor: AppColors.brandGreenPrimary,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                  'Cash collected — ${CurrencyFormatter.format(d.totalCents)}',
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: AppSpacing.buttonHeight,
            child: FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandGreenPrimary,
                  foregroundColor: AppColors.white),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.white))
                  : const Text('Confirm delivery',
                      style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: AppSpacing.x3l),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${m[d.month - 1]} ${d.year}, $hh:$mm';
  }

  /// Compose a detailed signed invoice (header, itemised table, totals, payment,
  /// signature) into a single PNG using a Canvas — no extra packages.
  Future<Uint8List> _buildSlip(
      Delivery d, Uint8List signaturePng, String receivedBy) async {
    final codec = await ui.instantiateImageCodec(signaturePng);
    final sigImage = (await codec.getNextFrame()).image;

    const width = 780.0;
    const margin = 44.0;
    const ink = Color(0xFF1A2B1F);
    const muted = Color(0xFF64748B);
    const green = Color(0xFF0B8F47);
    const rule = Color(0xFFE2E8F0);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(const Rect.fromLTWH(0, 0, width, 2400),
        Paint()..color = const Color(0xFFFFFFFF));

    double y = 0;

    void draw(String s, double x,
        {double size = 15,
        bool bold = false,
        Color color = ink,
        double? maxW,
        bool right = false}) {
      final tp = TextPainter(
        text: TextSpan(
            text: s,
            style: TextStyle(
                color: color,
                fontSize: size,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w400)),
        textDirection: TextDirection.ltr,
        maxLines: 3,
      )..layout(maxWidth: maxW ?? (width - margin - x));
      tp.paint(canvas, Offset(right ? (width - margin - tp.width) : x, y));
    }

    void hr() => canvas.drawLine(Offset(margin, y), Offset(width - margin, y),
        Paint()
          ..color = rule
          ..strokeWidth = 1.2);

    // ── Header band ──
    canvas.drawRect(const Rect.fromLTWH(0, 0, width, 104),
        Paint()..color = green);
    y = 28;
    draw('SpazaLink', margin, size: 30, bold: true, color: const Color(0xFFFFFFFF));
    y = 66;
    draw('DELIVERY INVOICE  •  PROOF OF DELIVERY', margin,
        size: 13, color: const Color(0xFFEAF7EF));

    // ── Order meta ──
    y = 132;
    draw('Invoice #${d.ref}', margin, size: 20, bold: true);
    y += 30;
    draw('Date: ${_fmtDate(DateTime.now())}', margin, size: 14, color: muted);
    y += 22;
    if (d.shopName.isNotEmpty) {
      draw('Shop: ${d.shopName}', margin, size: 14, color: muted);
      y += 22;
    }
    if (d.deliveryAddress.isNotEmpty) {
      draw('Deliver to: ${d.deliveryAddress}', margin, size: 14, color: muted);
      y += 26;
    }
    y += 8;

    // ── Items table ──
    hr();
    y += 12;
    draw('ITEM', margin, size: 12, bold: true, color: muted);
    draw('QTY × PRICE = TOTAL', margin, size: 12, bold: true, color: muted, right: true);
    y += 24;
    hr();
    y += 12;

    var subtotal = 0;
    for (final it in d.items) {
      subtotal += it.lineTotalCents;
      draw(it.name, margin, size: 14, maxW: width - 2 * margin - 250);
      draw(
          '${it.qty} × ${CurrencyFormatter.format(it.priceCents)} = ${CurrencyFormatter.format(it.lineTotalCents)}',
          margin,
          size: 13,
          right: true);
      y += 26;
    }
    if (d.items.isEmpty) {
      draw('(no item detail available)', margin, size: 13, color: muted);
      y += 26;
    }
    y += 6;
    hr();
    y += 14;

    final delivery = (d.totalCents - subtotal).clamp(0, d.totalCents);
    draw('Subtotal', margin, size: 14, color: muted);
    draw(CurrencyFormatter.format(subtotal), margin, size: 14, right: true);
    y += 24;
    draw('Delivery', margin, size: 14, color: muted);
    draw(CurrencyFormatter.format(delivery), margin, size: 14, right: true);
    y += 28;
    draw('TOTAL', margin, size: 19, bold: true);
    draw(CurrencyFormatter.format(d.totalCents), margin, size: 19, bold: true, right: true);
    y += 34;

    draw(
        d.isCod
            ? 'Payment: Cash on Delivery — ${_cashCollected ? "PAID (cash collected)" : "Unpaid"}'
            : 'Payment: ${d.paymentMethod}',
        margin,
        size: 14,
        bold: true,
        color: green);
    y += 40;

    // ── Signature ──
    hr();
    y += 18;
    draw('Received by: $receivedBy', margin, size: 15, bold: true);
    y += 26;
    draw('Received in good condition & signed below:', margin,
        size: 13, color: muted);
    y += 30;

    final sigW = width - 2 * margin;
    final scale = sigW / sigImage.width;
    final sigH = sigImage.height * scale;
    canvas.drawImageRect(
      sigImage,
      Rect.fromLTWH(0, 0, sigImage.width.toDouble(), sigImage.height.toDouble()),
      Rect.fromLTWH(margin, y, sigW, sigH),
      Paint(),
    );
    y += sigH + 10;
    canvas.drawLine(Offset(margin, y), Offset(margin + 320, y),
        Paint()
          ..color = muted
          ..strokeWidth = 1);
    y += 8;
    draw('Customer signature — ${_fmtDate(DateTime.now())}', margin,
        size: 11, color: muted);
    y += 34;
    draw('Thank you for shopping with SpazaLink', margin, size: 13, color: green);
    y += 36;

    final height = y.clamp(500.0, 2400.0);
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }
}
