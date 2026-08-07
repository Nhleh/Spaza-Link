import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

import '../../features/auth/providers/admin_auth_provider.dart';
import '../../features/auth/screens/admin_login_screen.dart';
import '../../features/categories/screens/admin_categories_screen.dart';
import '../../features/dashboard/screens/admin_dashboard_screen.dart';
import '../../features/orders/screens/admin_order_detail_screen.dart';
import '../../features/orders/screens/admin_orders_screen.dart';
import '../../features/products/screens/admin_product_form_screen.dart';
import '../../features/products/screens/admin_products_screen.dart';
import '../../features/messaging/screens/admin_communication_screen.dart';
import '../../features/ads/screens/admin_ads_screen.dart';
import '../../features/pools/screens/admin_pools_screen.dart';
import '../../features/reports/screens/admin_reports_screen.dart';
import '../../features/settings/screens/admin_settings_screen.dart';
import '../../features/shell/admin_shell.dart';
import '../../features/shops/screens/admin_shop_detail_screen.dart';
import '../../features/shops/screens/admin_shops_screen.dart';

/// Fires GoRouter re-evaluation whenever admin auth state changes.
class _AdminRouterNotifier extends ChangeNotifier {
  _AdminRouterNotifier(Ref ref) {
    ref.listen(adminAuthUidProvider, (_, __) => notifyListeners());
  }
}

/// GoRouter provider for the Admin Dashboard.
final adminRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AdminRouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: RouteConstants.adminLogin,
    debugLogDiagnostics: AppConfig.instance.isDevelopment,
    refreshListenable: notifier,
    redirect: (context, state) {
      final uid = ref.read(adminAuthUidProvider).valueOrNull;
      final isOnLogin =
          state.matchedLocation == RouteConstants.adminLogin;

      if (uid == null) {
        return isOnLogin ? null : RouteConstants.adminLogin;
      }
      return isOnLogin ? RouteConstants.adminDashboard : null;
    },
    routes: [
      // ── Auth (outside shell) ─────────────────────────────────────────────
      GoRoute(
        path: RouteConstants.adminLogin,
        name: 'admin-login',
        builder: (context, state) => const AdminLoginScreen(),
      ),

      // ── Main shell (sidebar + 8 branches) ───────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            AdminShell(navigationShell: shell),
        branches: [
          // Branch 0 — Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.adminDashboard,
                name: 'admin-dashboard',
                builder: (context, state) =>
                    const AdminDashboardScreen(),
              ),
            ],
          ),

          // Branch 1 — Orders
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.adminOrders,
                name: 'admin-orders',
                builder: (context, state) =>
                    const AdminOrdersScreen(),
                routes: [
                  GoRoute(
                    path: ':orderId',
                    name: 'admin-order-detail',
                    builder: (context, state) {
                      final id =
                          state.pathParameters['orderId']!;
                      final order = state.extra as OrderModel?;
                      return AdminOrderDetailScreen(
                          orderId: id, order: order);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 2 — Products
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.adminProducts,
                name: 'admin-products',
                builder: (context, state) =>
                    const AdminProductsScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    name: 'admin-product-create',
                    builder: (context, state) =>
                        const AdminProductFormScreen(),
                  ),
                  GoRoute(
                    path: ':productId/edit',
                    name: 'admin-product-edit',
                    builder: (context, state) {
                      final product =
                          state.extra as ProductModel?;
                      return AdminProductFormScreen(
                          product: product);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 3 — Categories
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.adminCategories,
                name: 'admin-categories',
                builder: (context, state) =>
                    const AdminCategoriesScreen(),
              ),
            ],
          ),

          // Branch 4 — Shops
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.adminShops,
                name: 'admin-shops',
                builder: (context, state) => const AdminShopsScreen(),
                routes: [
                  GoRoute(
                    path: 'message/:ownerId',
                    name: 'admin-shop-message',
                    builder: (context, state) => AdminCommunicationScreen(
                      initialOwnerId: state.pathParameters['ownerId'],
                    ),
                  ),
                  GoRoute(
                    path: ':shopId',
                    name: 'admin-shop-detail',
                    builder: (context, state) => AdminShopDetailScreen(
                      shopId: state.pathParameters['shopId']!,
                      shop: state.extra as ShopModel?,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Branch 5 — Drivers
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.adminDrivers,
                name: 'admin-drivers',
                builder: (context, state) =>
                    const _AdminPlaceholder(title: 'Drivers'),
                routes: [
                  GoRoute(
                    path: 'create',
                    name: 'admin-driver-create',
                    builder: (context, state) =>
                        const _AdminPlaceholder(
                            title: 'Add Driver'),
                  ),
                ],
              ),
            ],
          ),

          // Branch 6 — Reports
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.adminReports,
                name: 'admin-reports',
                builder: (context, state) => const AdminReportsScreen(),
              ),
            ],
          ),

          // Branch 7 — Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.adminSettings,
                name: 'admin-settings',
                builder: (context, state) => const AdminSettingsScreen(),
              ),
            ],
          ),

          // Branch 8 — Communication
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/communication',
                name: 'admin-communication',
                builder: (context, state) => const AdminCommunicationScreen(),
              ),
            ],
          ),

          // Branch 9 — Buying Pools (monitor)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/pools',
                name: 'admin-pools',
                builder: (context, state) => const AdminPoolsScreen(),
              ),
            ],
          ),

          // Branch 10 — Advertisements
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.adminAds,
                name: 'admin-ads',
                builder: (context, state) => const AdminAdsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: EmptyStateWidget(
          type: EmptyStateType.error,
          message: state.error?.toString(),
          actionLabel: 'Back to Dashboard',
          onAction: () => context.go(RouteConstants.adminDashboard),
        ),
      ),
    ),
  );
});

class _AdminPlaceholder extends StatelessWidget {
  const _AdminPlaceholder({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminDarkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.adminDarkSurface,
        automaticallyImplyLeading: false,
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.darkOnSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction_rounded,
                size: 48, color: AppColors.brandGold),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.darkOnSurface,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coming in Phase 9',
              style: TextStyle(color: AppColors.darkOnSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
