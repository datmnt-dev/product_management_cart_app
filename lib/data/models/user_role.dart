import 'package:flutter/material.dart';

enum AppRole { admin, manager, customer }

extension AppRoleX on AppRole {
  String get key {
    switch (this) {
      case AppRole.admin:
        return 'admin';
      case AppRole.manager:
        return 'manager';
      case AppRole.customer:
        return 'customer';
    }
  }

  String get label {
    switch (this) {
      case AppRole.admin:
        return 'Admin';
      case AppRole.manager:
        return 'Manager';
      case AppRole.customer:
        return 'Customer';
    }
  }

  String get vietnameseLabel {
    switch (this) {
      case AppRole.admin:
        return 'Quản trị viên';
      case AppRole.manager:
        return 'Quản lý';
      case AppRole.customer:
        return 'Khách hàng';
    }
  }

  String get description {
    switch (this) {
      case AppRole.admin:
        return 'Toàn quyền quản trị sản phẩm, doanh thu và ma trận phân quyền.';
      case AppRole.manager:
        return 'Vận hành sản phẩm và theo dõi doanh thu bán hàng.';
      case AppRole.customer:
        return 'Mua hàng, checkout và xem lịch sử đơn đã đặt.';
    }
  }

  IconData get icon {
    switch (this) {
      case AppRole.admin:
        return Icons.admin_panel_settings_outlined;
      case AppRole.manager:
        return Icons.manage_accounts_outlined;
      case AppRole.customer:
        return Icons.shopping_basket_outlined;
    }
  }

  /// Canonical role chrome color (single source of truth for headers, chips,
  /// demo panels). Do not reintroduce parallel accents on [AppTheme].
  ///
  /// | Role     | Hex       |
  /// |----------|-----------|
  /// | admin    | `#7C3AED` |
  /// | manager  | `#0F766E` |
  /// | customer | `#D97706` |
  Color get accentColor {
    switch (this) {
      case AppRole.admin:
        return const Color(0xFF7C3AED);
      case AppRole.manager:
        return const Color(0xFF0F766E);
      case AppRole.customer:
        return const Color(0xFFD97706);
    }
  }

  bool get canManageProducts {
    return this == AppRole.admin || this == AppRole.manager;
  }

  bool get canDeleteProducts {
    return this == AppRole.admin || this == AppRole.manager;
  }

  bool get canShop {
    return this == AppRole.customer;
  }

  bool get canViewRevenue {
    return this == AppRole.admin || this == AppRole.manager;
  }

  bool get canViewRoleMatrix {
    return this == AppRole.admin;
  }

  static AppRole fromKey(String? key) {
    switch (key) {
      case 'admin':
        return AppRole.admin;
      case 'manager':
        return AppRole.manager;
      case 'customer':
      default:
        return AppRole.customer;
    }
  }
}
