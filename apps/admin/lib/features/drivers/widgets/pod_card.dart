// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';

import '../providers/admin_drivers_provider.dart';

/// "Proof of Delivery" card shown on the admin order detail. Displays the
/// customer-signed slip once the order is delivered and offers a PDF download.
class PodCard extends ConsumerWidget {
  const PodCard({super.key, required this.orderId, required this.orderRef});

  final String orderId;
  final String orderRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final podAsync = ref.watch(orderPodUrlProvider(orderId));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.adminDarkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkOutline),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Proof of Delivery',
                    style: TextStyle(
                        color: AppColors.darkOnSurface,
                        fontWeight: FontWeight.w700)),
              ),
              podAsync.maybeWhen(
                data: (url) => url == null
                    ? const SizedBox.shrink()
                    : TextButton.icon(
                        onPressed: () => _downloadPdf(url, orderRef),
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('Download PDF'),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.brandGreenPrimary),
                      ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          podAsync.when(
            loading: () => const Center(
                child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                  color: AppColors.brandGreenPrimary),
            )),
            error: (_, __) => const Text('Could not load the slip.',
                style: TextStyle(color: AppColors.darkOnSurfaceVariant)),
            data: (url) {
              if (url == null) {
                return const Text(
                  'The signed slip will appear here once the driver completes '
                  'delivery and the customer signs.',
                  style: TextStyle(
                      color: AppColors.darkOnSurfaceVariant, fontSize: 13),
                );
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(url, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Text(
                        'Slip image unavailable.',
                        style: TextStyle(color: AppColors.darkOnSurfaceVariant))),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Opens the signed slip in a print-ready page; the browser's "Save as PDF"
  /// produces the downloadable proof.
  void _downloadPdf(String imageUrl, String ref) {
    final content = '''
<!doctype html><html><head><meta charset="utf-8"><title>Proof of Delivery - $ref</title>
<style>body{margin:0;font-family:Arial,sans-serif;text-align:center}
h3{margin:16px}img{max-width:100%;}</style></head>
<body onload="setTimeout(function(){window.print();},400)">
<h3>SpazaLink - Proof of Delivery - Order #$ref</h3>
<img src="$imageUrl"/>
</body></html>''';
    final blob = html.Blob([content], 'text/html;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
  }
}
