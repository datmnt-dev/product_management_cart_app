import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/orders/order_history_screen.dart';
import '../features/products/product_detail_screen.dart';
import '../features/products/product_form_screen.dart';
import '../features/products/product_list_screen.dart';
import '../features/roles/role_matrix_screen.dart';
import '../features/statistics/statistics_screen.dart';
import '../shared/widgets/empty_state.dart';
import '../state/auth_controller.dart';

class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const products = '/products';
  static const newProduct = '/products/new';
  static const productDetail = '/products/:id';
  static const editProduct = '/products/:id/edit';
  static const cart = '/cart';
  static const orders = '/orders';
  static const statistics = '/statistics';
  static const roles = '/roles';

  static String productDetails(String id) => '/products/$id';

  static String editProductDetails(String id) => '/products/$id/edit';
}

GoRouter buildAppRouter(AuthController authController) {
  return GoRouter(
    initialLocation: authController.isAuthenticated
        ? AppRoutes.products
        : AppRoutes.login,
    refreshListenable: authController,
    redirect: (context, state) {
      final isAuthenticated = authController.isAuthenticated;
      final user = authController.currentUser;
      final path = state.uri.path;
      final isAuthPage = path == AppRoutes.login || path == AppRoutes.register;

      if (!isAuthenticated && !isAuthPage) {
        return AppRoutes.login;
      }

      if (isAuthenticated && isAuthPage) {
        return AppRoutes.products;
      }

      if (user != null) {
        final isProductForm =
            path == AppRoutes.newProduct || path.endsWith('/edit');
        if (isProductForm && !user.canManageProducts) {
          return AppRoutes.products;
        }

        if (path == AppRoutes.cart && !user.canShop) {
          return AppRoutes.products;
        }

        if (path == AppRoutes.orders && !user.canShop) {
          return AppRoutes.products;
        }

        if (path == AppRoutes.statistics && !user.canViewRevenue) {
          return AppRoutes.products;
        }

        if (path == AppRoutes.roles && !user.canViewRoleMatrix) {
          return AppRoutes.products;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.products,
        builder: (context, state) => const ProductListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const ProductFormScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              return ProductDetailScreen(
                productId: state.pathParameters['id'] ?? '',
              );
            },
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) {
                  return ProductFormScreen(
                    productId: state.pathParameters['id'] ?? '',
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.cart,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: AppRoutes.orders,
        builder: (context, state) => const OrderHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.statistics,
        builder: (context, state) => const StatisticsScreen(),
      ),
      GoRoute(
        path: AppRoutes.roles,
        builder: (context, state) => const RoleMatrixScreen(),
      ),
    ],
    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(title: const Text('Không tìm thấy')),
        body: EmptyState(
          icon: Icons.travel_explore_outlined,
          title: 'Màn hình không tồn tại',
          message:
              'Đường dẫn không hợp lệ hoặc đã bị di chuyển. '
              'Quay lại cửa hàng để tiếp tục.',
          action: FilledButton.icon(
            onPressed: () => context.go(AppRoutes.products),
            icon: const Icon(Icons.storefront_outlined),
            label: const Text('Về cửa hàng'),
          ),
        ),
      );
    },
  );
}
