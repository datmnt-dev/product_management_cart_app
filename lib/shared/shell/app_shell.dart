import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/order_model.dart';
import '../../data/models/user_model.dart';
import '../../state/auth_controller.dart';
import '../../state/cart_controller.dart';
import '../../state/order_controller.dart';
import 'shell_destinations.dart';

/// Outer shell: tab chrome only. Branch screens keep nested Scaffolds.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  /// Prefer bottom nav on phone/tablet; rail on desktop web.
  static const double _railBreakpoint = 840;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    if (user == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return _ShellChrome(
      navigationShell: navigationShell,
      user: user,
    );
  }
}

class _ShellChrome extends StatelessWidget {
  const _ShellChrome({
    required this.navigationShell,
    required this.user,
  });

  final StatefulNavigationShell navigationShell;
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final visible = destinationsFor(user);
    var selected = visible.indexWhere(
      (d) => d.branchIndex == navigationShell.currentIndex,
    );
    if (selected < 0) selected = 0;

    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= AppShell._railBreakpoint;

    void onSelect(int visibleIndex) {
      HapticFeedback.selectionClick();
      final dest = visible[visibleIndex];
      navigationShell.goBranch(
        dest.branchIndex,
        initialLocation: visibleIndex == selected,
      );
    }

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selected,
              onDestinationSelected: onSelect,
              labelType: width >= 1024
                  ? NavigationRailLabelType.all
                  : NavigationRailLabelType.selected,
              destinations: [
                for (final d in visible)
                  NavigationRailDestination(
                    icon: _destinationIcon(context, d, selected: false),
                    selectedIcon: _destinationIcon(context, d, selected: true),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: onSelect,
        destinations: [
          for (final d in visible)
            NavigationDestination(
              icon: _destinationIcon(context, d, selected: false),
              selectedIcon: _destinationIcon(context, d, selected: true),
              label: d.label,
            ),
        ],
      ),
    );
  }

  Widget _destinationIcon(
    BuildContext context,
    ShellDestination d, {
    required bool selected,
  }) {
    final icon = Icon(selected ? d.selectedIcon : d.icon);

    if (d.branchIndex == ShellBranches.cart) {
      return Consumer<CartController>(
        builder: (context, cart, _) {
          final count = cart.totalQuantity;
          if (count <= 0) return icon;
          return Badge(
            label: Text(count > 99 ? '99+' : '$count'),
            child: icon,
          );
        },
      );
    }

    if (d.branchIndex == ShellBranches.orders) {
      return Consumer<OrderController>(
        builder: (context, orders, _) {
          final user = context.read<AuthController>().currentUser;
          // Staff: badge new "placed" orders. Customer: no alert provider.
          final count = user?.canManageOrders == true
              ? orders.countByStatus(OrderStatus.placed)
              : 0;
          if (count <= 0) return icon;
          return Badge(
            label: Text(count > 99 ? '99+' : '$count'),
            child: icon,
          );
        },
      );
    }

    return icon;
  }
}

/// Test helper: visible branch indices for a user (ordered).
@visibleForTesting
List<int> visibleBranchIndexesFor(AppUser user) {
  return destinationsFor(user).map((d) => d.branchIndex).toList();
}
