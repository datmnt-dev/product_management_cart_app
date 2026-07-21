import 'package:flutter/material.dart';

import '../../data/models/user_model.dart';

/// Fixed shell branch indices — never reorder per role.
abstract final class ShellBranches {
  static const int products = 0;
  static const int cart = 1;
  static const int orders = 2;
  static const int statistics = 3;
  static const int roles = 4;

  static const int count = 5;
}

/// One visible NavigationBar / NavigationRail destination.
class ShellDestination {
  const ShellDestination({
    required this.branchIndex,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  /// Fixed index into [StatefulNavigationShell] branches (0–4).
  final int branchIndex;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Role-aware visible destinations. Branch indices stay fixed.
List<ShellDestination> destinationsFor(AppUser user) {
  return <ShellDestination>[
    ShellDestination(
      branchIndex: ShellBranches.products,
      label: user.canManageProducts ? 'Kho hàng' : 'Cửa hàng',
      icon: Icons.storefront_outlined,
      selectedIcon: Icons.storefront,
    ),
    if (user.canShop)
      const ShellDestination(
        branchIndex: ShellBranches.cart,
        label: 'Giỏ',
        icon: Icons.shopping_bag_outlined,
        selectedIcon: Icons.shopping_bag,
      ),
    if (user.canShop || user.canManageOrders)
      ShellDestination(
        branchIndex: ShellBranches.orders,
        label: user.canManageOrders ? 'Bảng đơn' : 'Đơn',
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
      ),
    if (user.canViewRevenue)
      const ShellDestination(
        branchIndex: ShellBranches.statistics,
        label: 'Thống kê',
        icon: Icons.analytics_outlined,
        selectedIcon: Icons.analytics,
      ),
    if (user.canViewRoleMatrix)
      const ShellDestination(
        branchIndex: ShellBranches.roles,
        label: 'Quyền',
        icon: Icons.shield_outlined,
        selectedIcon: Icons.shield,
      ),
  ];
}
