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
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % widget.ads.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
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
    return Stack(
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.ads.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) => _AdCard(ad: widget.ads[i]),
        ),
        Positioned(
          bottom: 8,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.ads.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.white
                        .withValues(alpha: i == _index ? 0.95 : 0.6),
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
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ad.linkUrl == null ? null : _open,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          color: AppColors.brandGreenSurface,
          child: CachedNetworkImage(
            imageUrl: ad.imageUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            placeholder: (_, __) =>
                Container(color: AppColors.brandGreenSurface),
            // Missing image must never break the Shop (spec #17): fall back to
            // a titled placeholder card.
            errorWidget: (_, __, ___) => Container(
              color: AppColors.brandGreenSurface,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                ad.title.isEmpty ? 'Advertisement' : ad.title,
                textAlign: TextAlign.center,
                style: AppTypography.titleSmall.copyWith(
                    color: AppColors.brandGreenDark,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
