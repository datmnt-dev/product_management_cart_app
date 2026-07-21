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
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  /// Prefer bottom nav on phone/tablet portrait; rail on desktop web.
  static const double _railBreakpoint = 840;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    if (user == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    // Snackbars for status changes (optional if provider missing mid-reload).
    return _OrderAlertSnackHost(
      navigationShell: navigationShell,
      child: _ShellChrome(
        navigationShell: navigationShell,
        user: user,
      ),
    );
  }
}

/// Listens for new order alerts and shows a floating SnackBar.
class _OrderAlertSnackHost extends StatefulWidget {
  const _OrderAlertSnackHost({
    required this.navigationShell,
    required this.child,
  });

  final StatefulNavigationShell navigationShell;
  final Widget child;

  @override
  State<_OrderAlertSnackHost> createState() => _OrderAlertSnackHostState();
}

class _OrderAlertSnackHostState extends State<_OrderAlertSnackHost> {
  OrderAlertController? _alerts;
  int _lastUnread = 0;
  var _attached = false;

  OrderAlertController? _tryRead(BuildContext context) {
    try {
      return Provider.of<OrderAlertController>(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final alerts = _tryRead(context);
    if (alerts == null) {
      _detach();
      return;
    }
    if (!identical(_alerts, alerts)) {
      _detach();
      _alerts = alerts;
      _lastUnread = alerts.unreadCount;
      _alerts!.addListener(_onAlerts);
      _attached = true;
    }
  }

  void _detach() {
    if (_attached && _alerts != null) {
      _alerts!.removeListener(_onAlerts);
    }
    _alerts = null;
    _attached = false;
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
    _detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
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
    if (selected < 0) {
      selected = 0;
    }

    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= AppShell._railBreakpoint;

    void onSelect(int visibleIndex) {
      HapticFeedback.selectionClick();
      final dest = visible[visibleIndex];
      if (dest.branchIndex == ShellBranches.orders) {
        try {
          context.read<OrderAlertController>().markAllRead();
        } catch (_) {}
      }
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
          var count = 0;
          if (user?.canManageOrders == true) {
            count = orders.countByStatus(OrderStatus.placed);
          } else {
            try {
              count = context.read<OrderAlertController>().unreadCount;
            } catch (_) {
              count = 0;
            }
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
