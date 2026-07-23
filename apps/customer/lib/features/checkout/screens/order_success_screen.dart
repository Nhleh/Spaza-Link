import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({super.key, required this.order});

  final OrderModel order;

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with TickerProviderStateMixin {
  late final AnimationController _checkController;
  late final AnimationController _confettiController;
  late final Animation<double> _checkScale;
  late final Animation<double> _checkOpacity;
  late final Animation<double> _contentSlide;

  @override
  void initState() {
    super.initState();

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );
    _checkOpacity = CurvedAnimation(
      parent: _checkController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _contentSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _checkController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _checkController.forward();
        _confettiController.forward();
      }
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isOffline = order.syncStatus == SyncStatus.local;
    final displayRef = order.orderNumber.isNotEmpty
        ? order.orderNumber
        : '…syncing';

    return Scaffold(
      backgroundColor: AppColors.brandGreenPrimary,
      body: Stack(
        children: [
          // Confetti layer
          AnimatedBuilder(
            animation: _confettiController,
            builder: (_, __) => CustomPaint(
              painter: _ConfettiPainter(_confettiController.value),
              child: const SizedBox.expand(),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Check circle
                  ScaleTransition(
                    scale: _checkScale,
                    child: FadeTransition(
                      opacity: _checkOpacity,
                      child: Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.4),
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 60,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.x3l),

                  // Title + subtitle
                  AnimatedBuilder(
                    animation: _contentSlide,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(0, _contentSlide.value),
                      child: child,
                    ),
                    child: FadeTransition(
                      opacity: _checkOpacity,
                      child: Column(
                        children: [
                          Text(
                            'Order Placed!',
                            style: AppTypography.headlineMedium.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Thank you! We\'ve received your order.',
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.white.withValues(alpha: 0.85),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.x5l),

                  // Order details card
                  AnimatedBuilder(
                    animation: _contentSlide,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(0, _contentSlide.value),
                      child: child,
                    ),
                    child: FadeTransition(
                      opacity: _checkOpacity,
                      child: _OrderDetailsCard(
                        displayRef: displayRef,
                        isOffline: isOffline,
                        order: order,
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // CTA buttons
                  AnimatedBuilder(
                    animation: _contentSlide,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(0, _contentSlide.value),
                      child: child,
                    ),
                    child: FadeTransition(
                      opacity: _checkOpacity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: AppSpacing.buttonHeight,
                            child: ElevatedButton(
                              onPressed: () =>
                                  context.go(RouteConstants.orders),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.white,
                                foregroundColor: AppColors.brandGreenPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.buttonRadius),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Track My Order',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            height: AppSpacing.buttonHeight,
                            child: OutlinedButton(
                              onPressed: () => context.go(RouteConstants.home),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.white,
                                side: BorderSide(
                                  color:
                                      AppColors.white.withValues(alpha: 0.5),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.buttonRadius),
                                ),
                              ),
                              child: const Text(
                                'Continue Shopping',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.x3l),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderDetailsCard extends StatelessWidget {
  const _OrderDetailsCard({
    required this.displayRef,
    required this.isOffline,
    required this.order,
  });

  final String displayRef;
  final bool isOffline;
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          // Order ref
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order ref',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.white.withValues(alpha: 0.7),
                ),
              ),
              Text(
                displayRef,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
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
                'Total paid',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.white.withValues(alpha: 0.7),
                ),
              ),
              Text(
                CurrencyFormatter.format(order.totalCents),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Payment method
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.white.withValues(alpha: 0.7),
                ),
              ),
              Text(
                _paymentLabel(order.paymentMethod),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // Offline notice
          if (isOffline) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.brandGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    color: AppColors.brandGold,
                    size: 14,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Saved offline — will sync automatically when you reconnect.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _paymentLabel(String method) => switch (method) {
        PaymentMethod.cod => 'Cash on Delivery',
        PaymentMethod.payfast => 'PayFast',
        PaymentMethod.ozow => 'Ozow EFT',
        PaymentMethod.yoco => 'Yoco Card',
        _ => method,
      };
}

// ── Simple confetti painter ───────────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.progress);
  final double progress;

  static final _rng = math.Random(42);
  static final _particles = List.generate(60, (_) {
    return _Particle(
      x: _rng.nextDouble(),
      startY: -0.05 - _rng.nextDouble() * 0.2,
      speed: 0.3 + _rng.nextDouble() * 0.7,
      size: 4 + _rng.nextDouble() * 6,
      color: _colors[_rng.nextInt(_colors.length)],
      drift: (_rng.nextDouble() - 0.5) * 0.1,
      rotation: _rng.nextDouble() * math.pi * 2,
      rotSpeed: (_rng.nextDouble() - 0.5) * 8,
    );
  });

  static const _colors = [
    Color(0xFFF5C842),
    Color(0xFFFFFFFF),
    Color(0xFF4CAF50),
    Color(0xFFE91E63),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0 || progress == 1) return;

    for (final p in _particles) {
      final t = ((progress * p.speed) - 0.1).clamp(0.0, 1.0);
      if (t == 0) continue;

      final x = (p.x + p.drift * t) * size.width;
      final y = (p.startY + t * 1.4) * size.height;
      final angle = p.rotation + p.rotSpeed * t;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);

      final paint = Paint()..color = p.color.withValues(alpha: 1.0 - t * 0.5);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: p.size, height: p.size * 0.5),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

class _Particle {
  const _Particle({
    required this.x,
    required this.startY,
    required this.speed,
    required this.size,
    required this.color,
    required this.drift,
    required this.rotation,
    required this.rotSpeed,
  });

  final double x;
  final double startY;
  final double speed;
  final double size;
  final Color color;
  final double drift;
  final double rotation;
  final double rotSpeed;
}
