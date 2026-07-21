import 'package:flutter/material.dart';

enum AppRole { admin, manager, seller, customer }

extension AppRoleX on AppRole {
  String get key {
    switch (this) {
      case AppRole.admin:
        return 'admin';
      case AppRole.manager:
        return 'manager';
      case AppRole.seller:
        return 'seller';
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
      case AppRole.seller:
        return 'Seller';
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
      case AppRole.seller:
        return 'Người bán';
      case AppRole.customer:
        return 'Khách hàng';
    }
  }

  String get description {
    switch (this) {
      case AppRole.admin:
        return 'Quản trị toàn hệ thống: kho, điều phối mọi đơn, doanh thu, phân quyền.';
      case AppRole.manager:
        return 'Vận hành kho, điều phối đơn hàng và theo dõi doanh thu (không đổi role).';
      case AppRole.seller:
        return 'Tự quản lý sản phẩm, tồn kho và giao đơn của shop mình.';
      case AppRole.customer:
        return 'Mua hàng, checkout và theo dõi đơn của chính mình.';
    }
  }

  IconData get icon {
    switch (this) {
      case AppRole.admin:
        return Icons.admin_panel_settings_outlined;
      case AppRole.manager:
        return Icons.manage_accounts_outlined;
      case AppRole.seller:
        return Icons.storefront_outlined;
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
      case AppRole.seller:
        return const Color(0xFF2563EB);
      case AppRole.customer:
        return const Color(0xFFD97706);
    }
  }

  bool get canManageProducts {
    return this == AppRole.admin ||
        this == AppRole.manager ||
        this == AppRole.seller;
  }

  bool get canDeleteProducts {
    return this == AppRole.admin ||
        this == AppRole.manager ||
        this == AppRole.seller;
  }

  bool get canShop {
    return this == AppRole.customer || this == AppRole.seller;
  }

  bool get canViewRevenue {
    return this == AppRole.admin || this == AppRole.manager;
  }

  /// Admin + Manager operate all orders from the Statistics workflow.
  /// The `/orders` route remains customer-only for personal history.
  bool get canManageOrders {
    return this == AppRole.admin || this == AppRole.manager;
  }

  /// True for system operators (admin/manager), not shoppers.
  bool get isStaff => canManageOrders || canViewRevenue;

  bool get canViewRoleMatrix {
    return this == AppRole.admin;
  }

  static AppRole fromKey(String? key) {
    switch (key) {
      case 'admin':
        return AppRole.admin;
      case 'manager':
        return AppRole.manager;
      case 'seller':
        return AppRole.seller;
      case 'customer':
      default:
        return AppRole.customer;
    }
  }
}
