import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/user_model.dart';
import '../../state/auth_controller.dart';
import '../../state/cart_controller.dart';
import 'shell_destinations.dart';

/// Outer shell: tab chrome only. Branch screens keep nested Scaffolds.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const double _railBreakpoint = 600;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    if (user == null) {
      // Redirect should prevent this; fail soft.
      return const Scaffold(body: SizedBox.shrink());
    }

    final visible = destinationsFor(user);
    var selected = visible.indexWhere(
      (d) => d.branchIndex == navigationShell.currentIndex,
    );
    if (selected < 0) {
      selected = 0;
    }

    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= _railBreakpoint;

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selected,
              onDestinationSelected: (i) => _onSelect(i, visible, selected),
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
        onDestinationSelected: (i) => _onSelect(i, visible, selected),
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

  void _onSelect(
    int visibleIndex,
    List<ShellDestination> visible,
    int currentSelected,
  ) {
    HapticFeedback.selectionClick();
    final dest = visible[visibleIndex];
    navigationShell.goBranch(
      dest.branchIndex,
      initialLocation: visibleIndex == currentSelected,
    );
  }

  Widget _destinationIcon(
    BuildContext context,
    ShellDestination d, {
    required bool selected,
  }) {
    final icon = Icon(selected ? d.selectedIcon : d.icon);

    // Cart badge for shoppers
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
    return icon;
  }
}

/// Test helper: visible branch indices for a user (ordered).
@visibleForTesting
List<int> visibleBranchIndexesFor(AppUser user) {
  return destinationsFor(user).map((d) => d.branchIndex).toList();
}
