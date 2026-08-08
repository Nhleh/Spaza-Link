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
  }

  @override
  void dispose() {
    _sig.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final d = widget.delivery;
    if (_sig.isEmpty) {
      _snack('Please ask the customer to sign first.');
      return;
    }
    if (d.isCod && !_cashCollected) {
      _snack('Confirm the cash was collected to complete this delivery.');
      return;
    }
    setState(() => _busy = true);
    try {
      final sigPng = await _sig.toPngBytes();
      if (sigPng == null) throw Exception('Could not read the signature.');
      final slipPng = await _buildSlip(d, sigPng);

      await ref.read(driverDeliveryRepositoryProvider).completeDelivery(
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

  /// Compose the signed proof-of-delivery slip (order details + signature) into
  /// a single PNG using a Canvas — no extra packages.
  Future<Uint8List> _buildSlip(Delivery d, Uint8List signaturePng) async {
    final codec = await ui.instantiateImageCodec(signaturePng);
    final sigImage = (await codec.getNextFrame()).image;

    const width = 720.0;
    final recorder = ui.PictureRecorder();
    // Two-pass: first measure by drawing to a tall canvas, then crop height.
    final canvas = Canvas(recorder);
    canvas.drawRect(const Rect.fromLTWH(0, 0, width, 1600),
        Paint()..color = const Color(0xFFFFFFFF));

    double y = 32;
    void line(String text,
        {double size = 20, bool bold = false, Color color = const Color(0xFF1A2B1F)}) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
              color: color,
              fontSize: size,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w400),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 3,
      )..layout(maxWidth: width - 64);
      tp.paint(canvas, Offset(32, y));
      y += tp.height + 8;
    }

    line('SpazaLink — Proof of Delivery', size: 24, bold: true, color: const Color(0xFF0B8F47));
    line('Order #${d.ref}', size: 18, bold: true);
    line('Date: ${DateTime.now().toLocal()}'.split('.').first, size: 14, color: const Color(0xFF4A5E4E));
    y += 6;
    line('Items', size: 16, bold: true);
    for (final it in d.items) {
      line('• ${it.name}  ×${it.qty}   ${CurrencyFormatter.format(it.lineTotalCents)}',
          size: 14);
    }
    y += 4;
    line('Total: ${CurrencyFormatter.format(d.totalCents)}', size: 18, bold: true);
    line(
        d.isCod
            ? 'Payment: Cash on Delivery — Cash collected: ${_cashCollected ? "Yes" : "No"}'
            : 'Payment: ${d.paymentMethod}',
        size: 14, color: const Color(0xFF4A5E4E));
    if (d.deliveryAddress.isNotEmpty) {
      line('Delivered to: ${d.deliveryAddress}', size: 14, color: const Color(0xFF4A5E4E));
    }
    y += 12;
    line('Received & signed by the customer:', size: 14, bold: true);
    y += 6;

    // Signature (scaled to fit width, keeping aspect).
    final sigW = width - 64;
    final scale = sigW / sigImage.width;
    final sigH = sigImage.height * scale;
    final dst = Rect.fromLTWH(32, y, sigW, sigH);
    canvas.drawImageRect(
      sigImage,
      Rect.fromLTWH(0, 0, sigImage.width.toDouble(), sigImage.height.toDouble()),
      dst,
      Paint(),
    );
    y += sigH + 24;

    final height = y.clamp(300.0, 1600.0);
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }
}
