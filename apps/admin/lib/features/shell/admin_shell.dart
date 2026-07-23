import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spazalink_core/core.dart';

import '../auth/providers/admin_auth_provider.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _branches = [
    _SidebarItem(icon: Icons.dashboard_rounded,     label: 'Dashboard',  index: 0),
    _SidebarItem(icon: Icons.receipt_long_rounded,  label: 'Orders',     index: 1),
    _SidebarItem(icon: Icons.inventory_2_rounded,   label: 'Products',   index: 2),
    _SidebarItem(icon: Icons.category_rounded,      label: 'Categories', index: 3),
    _SidebarItem(icon: Icons.store_rounded,         label: 'Shops',      index: 4),
    _SidebarItem(icon: Icons.delivery_dining_rounded, label: 'Drivers',  index: 5),
    _SidebarItem(icon: Icons.bar_chart_rounded,     label: 'Reports',    index: 6),
    _SidebarItem(icon: Icons.settings_rounded,      label: 'Settings',   index: 7),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.adminDarkBackground,
      body: Row(
        children: [
          _AdminSidebar(
            currentIndex: navigationShell.currentIndex,
            onDestinationSelected: (i) => navigationShell.goBranch(
              i,
              initialLocation: i == navigationShell.currentIndex,
            ),
          ),
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: AppColors.adminDarkOutline,
          ),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

// ── Sidebar ───────────────────────────────────────────────────────────────────

class _AdminSidebar extends ConsumerWidget {
  const _AdminSidebar({
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _mainItems = [0, 1, 2, 3];
  static const _opsItems  = [4, 5];
  static const _sysItems  = [6, 7];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 220,
      child: Container(
        color: AppColors.adminDarkSurface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.brandGreenPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.link_rounded,
                      color: AppColors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Spaza',
                          style: TextStyle(
                            color: AppColors.darkOnSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: 'Link',
                          style: TextStyle(
                            color: AppColors.brandGold,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Divider(color: AppColors.adminDarkOutline, height: 1),
            ),

            const SizedBox(height: 12),

            // Nav items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _SectionLabel('MAIN'),
                  ..._mainItems.map((i) => _NavTile(
                        item: AdminShell._branches[i],
                        isSelected: currentIndex == i,
                        onTap: () => onDestinationSelected(i),
                      )),
                  const SizedBox(height: 8),
                  _SectionLabel('OPERATIONS'),
                  ..._opsItems.map((i) => _NavTile(
                        item: AdminShell._branches[i],
                        isSelected: currentIndex == i,
                        onTap: () => onDestinationSelected(i),
                      )),
                  const SizedBox(height: 8),
                  _SectionLabel('SYSTEM'),
                  ..._sysItems.map((i) => _NavTile(
                        item: AdminShell._branches[i],
                        isSelected: currentIndex == i,
                        onTap: () => onDestinationSelected(i),
                      )),
                ],
              ),
            ),

            // Sign out
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Divider(color: AppColors.adminDarkOutline, height: 1),
            ),
            _SignOutTile(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.darkOnSurfaceVariant,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _SidebarItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: isSelected
            ? AppColors.brandGreenPrimary.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 18,
                  color: isSelected
                      ? AppColors.brandGreenPrimary
                      : AppColors.darkOnSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.brandGreenPrimary
                        : AppColors.darkOnSurface,
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignOutTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () async {
            await adminSignOut(ref);
            if (context.mounted) context.go(RouteConstants.adminLogin);
          },
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.logout_rounded,
                    size: 18, color: AppColors.darkOnSurfaceVariant),
                SizedBox(width: 10),
                Text(
                  'Sign Out',
                  style: TextStyle(
                    color: AppColors.darkOnSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarItem {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.index,
  });

  final IconData icon;
  final String label;
  final int index;
}
