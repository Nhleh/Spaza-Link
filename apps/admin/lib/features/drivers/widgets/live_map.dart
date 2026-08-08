// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// Embedded Google Map centred on a driver's position, using Google's keyless
/// embed (no API key / billing). Web only — the admin runs on the web.
class LiveMap extends StatelessWidget {
  const LiveMap({super.key, required this.lat, required this.lng, this.height = 260});

  final double lat;
  final double lng;
  final double height;

  // Register one iframe factory per distinct position.
  static final Set<String> _registered = {};

  @override
  Widget build(BuildContext context) {
    final key = 'gmap_${lat.toStringAsFixed(5)}_${lng.toStringAsFixed(5)}';
    if (!_registered.contains(key)) {
      _registered.add(key);
      ui_web.platformViewRegistry.registerViewFactory(key, (int _) {
        final iframe = html.IFrameElement()
          ..src =
              'https://www.google.com/maps?q=$lat,$lng&z=16&hl=en&output=embed'
          ..style.border = '0'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allowFullscreen = true;
        return iframe;
      });
    }
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        // Key forces a fresh view when the position changes.
        child: HtmlElementView(key: ValueKey(key), viewType: key),
      ),
    );
  }
}
