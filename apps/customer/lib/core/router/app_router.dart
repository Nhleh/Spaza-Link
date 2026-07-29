import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/pending_approval_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/rejected_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/catalogue/screens/catalogue_screen.dart';
import '../../features/catalogue/screens/category_products_screen.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../features/checkout/screens/checkout_screen.dart';
import '../../features/checkout/screens/order_success_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/main_shell.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/profile_edit_screens.dart';
import '../../features/orders/screens/order_detail_screen.dart';
import '../../features/orders/screens/order_tracking_screen.dart';
import '../../features/orders/screens/orders_screen.dart';
import '../../features/products/screens/product_detail_screen.dart';
import '../../features/search/screens/search_screen.dart';

/// Fires GoRouter re-evaluation whenever auth or shop state changes.
class _CustomerRouterNotifier extends ChangeNotifier {
  _CustomerRouterNotifier(Ref ref) {
    ref.listen(authUidProvider, (_, __) => notifyListeners());
    ref.listen(currentShopProvider, (_, __) => notifyListeners());
  }
}

/// GoRouter provider for the Customer App.
final customerRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _CustomerRouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: RouteConstants.splash,
    debugLogDiagnostics: AppConfig.instance.isDevelopment,
    refreshListenable: notifier,
    redirect: _buildRedirect(ref),
    routes: [
      // ── Auth ──────────────────────────────────────────────────────────────

      GoRoute(
        path: RouteConstants.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(
        path: RouteConstants.welcome,
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),

      GoRoute(
        path: RouteConstants.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: RouteConstants.otpVerify,
        name: 'otp-verify',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OtpScreen(
            phoneNumber: (extra?['phone'] as String?) ?? '',
          );
        },
      ),

      GoRoute(
        path: RouteConstants.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      GoRoute(
        path: RouteConstants.pendingApproval,
        name: 'pending-approval',
        builder: (context, state) => const PendingApprovalScreen(),
      ),

      GoRoute(
        path: RouteConstants.rejected,
        name: 'rejected',
        builder: (context, state) => const RejectedScreen(),
      ),

      // ── Main shell (tabs) ─────────────────────────────────────────────────

      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            MainShell(navigationShell: shell),
        branches: [
          // Tab 0 — Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.home,
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Tab 1 — Catalogue
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.catalogue,
                name: 'catalogue',
                builder: (context, state) => const CatalogueScreen(),
                routes: [
                  GoRoute(
                    path: ':categoryId',
                    name: 'catalogue-category',
                    builder: (context, state) {
                      final catId = state.pathParameters['categoryId']!;
                      final cat = state.extra as CategoryModel?;
                      return CategoryProductsScreen(
                        categoryId: catId,
                        category: cat,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // Tab 2 — Cart
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.cart,
                name: 'cart',
                builder: (context, state) => const CartScreen(),
              ),
            ],
          ),

          // Tab 3 — Orders (Phase 7)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.orders,
                name: 'orders',
                builder: (context, state) => const OrdersScreen(),
                routes: [
                  GoRoute(
                    path: ':orderId',
                    name: 'order-detail',
                    builder: (context, state) {
                      final id = state.pathParameters['orderId']!;
                      final order = state.extra as OrderModel?;
                      return OrderDetailScreen(orderId: id, order: order);
                    },
                    routes: [
                      GoRoute(
                        path: 'tracking',
                        name: 'order-tracking',
                        builder: (context, state) {
                          final id = state.pathParameters['orderId']!;
                          final order = state.extra as OrderModel?;
                          return OrderTrackingScreen(orderId: id, order: order);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Tab 4 — Profile (Phase 8)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.profile,
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'shop-info',
                    name: 'profile-shop-info',
                    builder: (context, state) => const ShopInformationScreen(),
                  ),
                  GoRoute(
                    path: 'delivery-addresses',
                    name: 'profile-delivery',
                    builder: (context, state) => const DeliveryAddressesScreen(),
                  ),
                  GoRoute(
                    path: 'payment-methods',
                    name: 'profile-payment',
                    builder: (context, state) => const PaymentMethodsScreen(),
                  ),
                  GoRoute(
                    path: 'change-password',
                    name: 'profile-password',
                    builder: (context, state) => const ChangePasswordScreen(),
                  ),
                  GoRoute(
                    path: 'notifications',
                    name: 'profile-notifications',
                    builder: (context, state) =>
                        const NotificationSettingsScreen(),
                  ),
                  GoRoute(
                    path: 'support',
                    name: 'profile-support',
                    builder: (context, state) => const HelpSupportScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // ── Full-screen routes (above shell) ──────────────────────────────────

      GoRoute(
        path: RouteConstants.productDetail,
        name: 'product-detail',
        builder: (context, state) {
          final productId = state.pathParameters['productId']!;
          final product = state.extra as ProductModel?;
          return ProductDetailScreen(productId: productId, product: product);
        },
      ),

      GoRoute(
        path: RouteConstants.search,
        name: 'search',
        builder: (context, state) {
          final query = state.uri.queryParameters['q'] ?? '';
          return SearchScreen(initialQuery: query);
        },
      ),

      GoRoute(
        path: RouteConstants.checkout,
        name: 'checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),

      GoRoute(
        path: RouteConstants.orderSuccess,
        name: 'order-success',
        builder: (context, state) {
          final order = state.extra as OrderModel?;
          if (order == null) return const _PlaceholderScreen(title: 'Order Placed!', phase: 6);
          return OrderSuccessScreen(order: order);
        },
      ),

      GoRoute(
        path: RouteConstants.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      GoRoute(
        path: RouteConstants.settings,
        name: 'settings',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Settings', phase: 8),
      ),

      GoRoute(
        path: RouteConstants.support,
        name: 'support',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Help & Support', phase: 8),
      ),

      GoRoute(
        path: RouteConstants.helpCentre,
        name: 'help',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Help Centre', phase: 8),
      ),

      GoRoute(
        path: RouteConstants.noInternet,
        name: 'no-internet',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'No Internet', phase: 0),
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: EmptyStateWidget(
          type: EmptyStateType.error,
          message: state.error?.toString(),
          actionLabel: 'Go Home',
          onAction: () => context.go(RouteConstants.splash),
        ),
      ),
    ),
  );
});

String? Function(BuildContext, GoRouterState) _buildRedirect(Ref ref) {
  return (context, state) {
    final loc = state.matchedLocation;

    final authAsync = ref.read(authUidProvider);
    if (authAsync.isLoading) return null;

    final uid = authAsync.valueOrNull;

    const authRoutes = {
      RouteConstants.splash,
      RouteConstants.welcome,
      RouteConstants.login,
      RouteConstants.otpVerify,
      RouteConstants.register,
      RouteConstants.pendingApproval,
      RouteConstants.rejected,
    };

    if (uid == null) {
      return authRoutes.contains(loc) ? null : RouteConstants.welcome;
    }

    final shopAsync = ref.read(currentShopProvider);
    if (shopAsync.isLoading) return null;

    final shop = shopAsync.valueOrNull;

    if (shop == null) {
      return loc == RouteConstants.register ? null : RouteConstants.register;
    }

    // A rejected/suspended shop is blocked by the admin — keep that gate.
    if (shop.status == AppConstants.shopStatusRejected ||
        shop.status == AppConstants.shopStatusSuspended) {
      return loc == RouteConstants.rejected ? null : RouteConstants.rejected;
    }

    // The person's profile is approved on sign-up, so a pending OR approved
    // shop lets the user straight into the app. Only the shop itself waits on
    // admin approval — its status is surfaced on the Profile screen.
    return authRoutes.contains(loc) ? RouteConstants.home : null;
  };
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title, this.phase = 0});
  final String title;
  final int phase;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.brandGreenPrimary,
        foregroundColor: AppColors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.construction_rounded,
              size: 48,
              color: AppColors.brandGold,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (phase > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Coming in Phase $phase',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.lightOnSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
