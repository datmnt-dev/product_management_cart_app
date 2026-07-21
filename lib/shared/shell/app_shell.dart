import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/order_model.dart';
import '../../data/models/user_model.dart';
import '../../state/auth_controller.dart';
import '../../state/cart_controller.dart';
import '../../state/order_alert_controller.dart';
import '../../state/order_controller.dart';
import 'shell_destinations.dart';

/// Outer shell: tab chrome only. Branch screens keep nested Scaffolds.
class AppShell extends StatefulWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const double _railBreakpoint = 600;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  OrderAlertController? _alerts;
  int _lastUnread = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final alerts = context.read<OrderAlertController>();
    if (!identical(_alerts, alerts)) {
      _alerts?.removeListener(_onAlerts);
      _alerts = alerts;
      _alerts!.addListener(_onAlerts);
    }
  }

  void _onAlerts() {
    final alerts = _alerts;
    if (alerts == null || !mounted) return;
    if (alerts.unreadCount > _lastUnread && alerts.latest != null) {
      final latest = alerts.latest!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(latest.message),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Đơn',
            onPressed: () {
              widget.navigationShell.goBranch(ShellBranches.orders);
              alerts.markAllRead();
            },
          ),
        ),
      );
    }
    _lastUnread = alerts.unreadCount;
  }

  @override
  void dispose() {
    _alerts?.removeListener(_onAlerts);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    if (user == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final visible = destinationsFor(user);
    var selected = visible.indexWhere(
      (d) => d.branchIndex == widget.navigationShell.currentIndex,
    );
    if (selected < 0) {
      selected = 0;
    }

    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= AppShell._railBreakpoint;

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
            Expanded(child: widget.navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: widget.navigationShell,
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
    if (dest.branchIndex == ShellBranches.orders) {
      context.read<OrderAlertController>().markAllRead();
    }
    widget.navigationShell.goBranch(
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
      return Consumer2<OrderAlertController, OrderController>(
        builder: (context, alerts, orders, _) {
          final user = context.read<AuthController>().currentUser;
          var count = 0;
          if (user?.canManageOrders == true) {
            count = orders.countByStatus(OrderStatus.placed);
          } else {
            count = alerts.unreadCount;
          }
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
