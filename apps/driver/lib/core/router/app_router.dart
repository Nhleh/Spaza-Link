import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

import '../../features/auth/providers/driver_auth_provider.dart';
import '../../features/auth/screens/driver_login_screen.dart';
import '../../features/auth/screens/driver_otp_screen.dart';
import '../../features/deliveries/screens/driver_splash_screen.dart';

/// Fires GoRouter re-evaluation whenever driver auth state changes.
class _DriverRouterNotifier extends ChangeNotifier {
  _DriverRouterNotifier(Ref ref) {
    ref.listen(driverAuthUidProvider, (_, __) => notifyListeners());
  }
}

/// GoRouter provider for the Driver App.
final driverRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _DriverRouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: RouteConstants.driverSplash,
    debugLogDiagnostics: AppConfig.instance.isDevelopment,
    refreshListenable: notifier,
    redirect: (context, state) {
      final uid = ref.read(driverAuthUidProvider).valueOrNull;
      final loc = state.matchedLocation;
      const loginFlow = {
        RouteConstants.driverSplash,
        RouteConstants.driverLogin,
        RouteConstants.driverOtpVerify,
      };

      if (uid == null) {
        return loginFlow.contains(loc) ? null : RouteConstants.driverLogin;
      }
      return loginFlow.contains(loc) ? RouteConstants.driverDeliveries : null;
    },
    routes: [
      GoRoute(
        path: RouteConstants.driverSplash,
        name: 'driver-splash',
        builder: (context, state) => const DriverSplashScreen(),
      ),
      GoRoute(
        path: RouteConstants.driverLogin,
        name: 'driver-login',
        builder: (context, state) => const DriverLoginScreen(),
      ),
      GoRoute(
        path: RouteConstants.driverOtpVerify,
        name: 'driver-otp-verify',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return DriverOtpScreen(
            phoneNumber: (extra?['phone'] as String?) ?? '',
          );
        },
      ),
      GoRoute(
        path: RouteConstants.driverDeliveries,
        name: 'driver-deliveries',
        builder: (context, state) =>
            const _DriverPlaceholder(title: 'My Deliveries'),
        routes: [
          GoRoute(
            path: ':deliveryId',
            name: 'driver-delivery-detail',
            builder: (context, state) =>
                const _DriverPlaceholder(title: 'Delivery Detail'),
            routes: [
              GoRoute(
                path: 'proof',
                name: 'driver-delivery-proof',
                builder: (context, state) =>
                    const _DriverPlaceholder(title: 'Proof of Delivery'),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RouteConstants.driverMap,
        name: 'driver-map',
        builder: (context, state) =>
            const _DriverPlaceholder(title: 'Live Map'),
      ),
      GoRoute(
        path: RouteConstants.driverHistory,
        name: 'driver-history',
        builder: (context, state) =>
            const _DriverPlaceholder(title: 'Delivery History'),
      ),
      GoRoute(
        path: RouteConstants.driverEarnings,
        name: 'driver-earnings',
        builder: (context, state) =>
            const _DriverPlaceholder(title: 'Earnings'),
      ),
      GoRoute(
        path: RouteConstants.driverProfile,
        name: 'driver-profile',
        builder: (context, state) =>
            const _DriverPlaceholder(title: 'Profile'),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: EmptyStateWidget(
          type: EmptyStateType.error,
          message: state.error?.toString(),
          actionLabel: 'Back to Deliveries',
          onAction: () => context.go(RouteConstants.driverDeliveries),
        ),
      ),
    ),
  );
});

class _DriverPlaceholder extends StatelessWidget {
  const _DriverPlaceholder({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_shipping_rounded,
                size: 48, color: AppColors.brandGreenPrimary),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Coming in Phase 9',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.lightOnSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
