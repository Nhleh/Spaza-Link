import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/advertisement.dart';
import '../providers/ads_provider.dart';

/// Sliding advertisement banner shown on the Shop page between the categories
/// and the products (spec #8). Sized to match the Next Delivery card. Hidden
/// entirely when there are no active ads (spec #9); a single ad is static and
/// multiple ads auto-advance as a carousel (spec #11).
class AdBanner extends ConsumerWidget {
  const AdBanner({super.key});

  /// Matches the Next Delivery card's visual height.
  static const double _height = 108;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ads = ref.watch(activeAdsProvider).valueOrNull ?? const [];
    if (ads.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingH,
        AppSpacing.md,
        AppSpacing.screenPaddingH,
        0,
      ),
      child: SizedBox(
        height: _height,
        child: ads.length == 1
            ? _AdCard(ad: ads.first)
            : _AdCarousel(ads: ads),
      ),
    );
  }
}

class _AdCarousel extends StatefulWidget {
  const _AdCarousel({required this.ads});
  final List<AdvertisementModel> ads;

  @override
  State<_AdCarousel> createState() => _AdCarouselState();
}

class _AdCarouselState extends State<_AdCarousel> {
  // Start from a high page so the carousel can keep advancing in a single
  // (forward) direction indefinitely, looping seamlessly without ever jumping
  // backwards.
  static const int _base = 100000;
  late final PageController _controller;
  Timer? _timer;
  int _page = _base;

  int get _activeIndex => _page % widget.ads.length;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: _base);
    // Each ad stays on screen for 12 seconds, then always slides forward.
    _timer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final len = widget.ads.length;
    return Stack(
      children: [
        PageView.builder(
          controller: _controller,
          // Infinite in the forward direction; index is mapped back onto the
          // real ad list with a modulo.
          itemCount: null,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) => _AdCard(ad: widget.ads[((i % len) + len) % len]),
        ),
        Positioned(
          bottom: 8,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < len; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _activeIndex ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.white
                        .withValues(alpha: i == _activeIndex ? 0.95 : 0.6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdCard extends StatelessWidget {
  const _AdCard({required this.ad});
  final AdvertisementModel ad;

  Future<void> _open() async {
    final link = ad.linkUrl;
    if (link == null || link.isEmpty) return;
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    // Don't gate on canLaunchUrl — on Android 11+ it returns false for https
    // unless a <queries> entry is declared, which silently blocked the link.
    // Open in the external browser; pressing Back returns to the app.
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {/* nothing we can do */}
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLink = ad.linkUrl != null && ad.linkUrl!.isNotEmpty;
    return GestureDetector(
      onTap: hasLink ? _open : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Ad image.
            Container(
              color: AppColors.brandGreenSurface,
              child: CachedNetworkImage(
                imageUrl: ad.imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: AppColors.brandGreenSurface),
                // Missing image must never break the Shop (spec #17).
                errorWidget: (_, __, ___) =>
                    Container(color: AppColors.brandGreenPrimary),
              ),
            ),
            // Left-to-right dark scrim so the title/CTA stay readable over any
            // image.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xCC0A2A18), Color(0x330A2A18), Color(0x00000000)],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
              child: SizedBox.expand(),
            ),
            // Title + optional CTA.
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Sponsored',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Flexible(
                    child: Text(
                      ad.title.isEmpty ? 'Advertisement' : ad.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ),
                  if (hasLink) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Shop Now',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.brandGreenDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 14, color: AppColors.brandGreenDark),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
