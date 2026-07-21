import 'package:flutter_test/flutter_test.dart';
import 'package:product_management_cart_app/data/models/user_model.dart';
import 'package:product_management_cart_app/data/models/user_role.dart';
import 'package:product_management_cart_app/shared/shell/shell_destinations.dart';

AppUser _user(AppRole role) {
  return AppUser(
    id: 'u-${role.key}',
    fullName: role.label,
    email: '${role.key}@store.local',
    passwordHash: '',
    role: role,
    createdAt: DateTime(2026),
  );
}

void main() {
  group('destinationsFor role matrix', () {
    test('customer has store, cart, orders (3 tabs)', () {
      final dests = destinationsFor(_user(AppRole.customer));
      expect(dests.map((d) => d.branchIndex).toList(), [
        ShellBranches.products,
        ShellBranches.cart,
        ShellBranches.orders,
      ]);
      expect(dests.length, 3);
    });

    test('manager has inventory + statistics (2 tabs)', () {
      final dests = destinationsFor(_user(AppRole.manager));
      expect(dests.map((d) => d.branchIndex).toList(), [
        ShellBranches.products,
        ShellBranches.statistics,
      ]);
      expect(dests.length, 2);
      expect(dests.any((d) => d.branchIndex == ShellBranches.orders), isFalse);
    });

    test('admin has inventory, statistics, roles (3 tabs)', () {
      final dests = destinationsFor(_user(AppRole.admin));
      expect(dests.map((d) => d.branchIndex).toList(), [
        ShellBranches.products,
        ShellBranches.statistics,
        ShellBranches.roles,
      ]);
      expect(dests.length, 3);
      // Admin = system owner: operates orders inside Statistics, not Orders tab.
      expect(dests.any((d) => d.branchIndex == ShellBranches.cart), isFalse);
      expect(dests.any((d) => d.branchIndex == ShellBranches.orders), isFalse);
      expect(_user(AppRole.admin).canManageOrders, isTrue);
      expect(_user(AppRole.admin).canShop, isFalse);
    });

    test('branch indexes are fixed constants', () {
      expect(ShellBranches.products, 0);
      expect(ShellBranches.cart, 1);
      expect(ShellBranches.orders, 2);
      expect(ShellBranches.statistics, 3);
      expect(ShellBranches.roles, 4);
    });
  });
}
