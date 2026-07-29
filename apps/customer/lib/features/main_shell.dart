import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

import 'auth/providers/auth_provider.dart';
import 'cart/providers/cart_provider.dart';
import 'messages/providers/messages_provider.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    _TabItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
      route: RouteConstants.home,
    ),
    _TabItem(
      icon: Icons.storefront_outlined,
      activeIcon: Icons.storefront_rounded,
      label: 'Shop',
      route: RouteConstants.catalogue,
    ),
    _TabItem(
      icon: Icons.shopping_cart_outlined,
      activeIcon: Icons.shopping_cart_rounded,
      label: 'Cart',
      route: RouteConstants.cart,
    ),
    _TabItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: 'Orders',
      route: RouteConstants.orders,
    ),
    _TabItem(
      icon: Icons.mail_outline_rounded,
      activeIcon: Icons.mail_rounded,
      label: 'Messages',
      route: '/messages',
    ),
    _TabItem(
      icon: Icons.person_outlined,
      activeIcon: Icons.person_rounded,
      label: 'Account',
      route: RouteConstants.profile,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopId = ref.watch(currentShopProvider).valueOrNull?.id ?? '';
    final cartCount = ref.watch(cartItemCountProvider(shopId));
    final unread = ref.watch(unreadMessagesProvider);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        backgroundColor: AppColors.lightSurface,
        indicatorColor: AppColors.brandGreenSurface,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: List.generate(_tabs.length, (i) {
          final tab = _tabs[i];
          final isActive = navigationShell.currentIndex == i;

          // Cart (index 2) and Messages (index 4) tabs get a count badge.
          final badgeCount = i == 2 ? cartCount : (i == 4 ? unread : 0);
          if (badgeCount > 0) {
            return NavigationDestination(
              icon: Badge(
                label: Text(badgeCount > 99 ? '99+' : '$badgeCount'),
                backgroundColor: AppColors.brandGold,
                textColor: AppColors.white,
                child: Icon(
                  isActive ? tab.activeIcon : tab.icon,
                  color: isActive
                      ? AppColors.brandGreenPrimary
                      : AppColors.lightOnSurfaceVariant,
                ),
              ),
              label: tab.label,
            );
          }

          return NavigationDestination(
            icon: Icon(
              isActive ? tab.activeIcon : tab.icon,
              color: isActive
                  ? AppColors.brandGreenPrimary
                  : AppColors.lightOnSurfaceVariant,
            ),
            label: tab.label,
          );
        }),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
}
