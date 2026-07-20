import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:product_management_cart_app/data/models/product_model.dart';
import 'package:product_management_cart_app/shared/components/product_card.dart';
import 'package:product_management_cart_app/state/cart_controller.dart';
import 'package:provider/provider.dart';

Product _product({
  required String id,
  int stock = 0,
  ProductStatus status = ProductStatus.active,
}) {
  return Product(
    id: id,
    sku: 'SKU-$id',
    name: 'Sản phẩm $id',
    description: 'Mô tả',
    category: ProductCategory.phone,
    price: 100000,
    stockQuantity: stock,
    status: status,
    imageUrl: '',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

Widget _harness({required Widget child, required CartController cart}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: SizedBox(width: 200, height: 320, child: child),
        ),
      ),
      GoRoute(
        path: '/products/:id',
        builder: (context, state) => const Scaffold(body: Text('detail')),
      ),
    ],
  );

  return ChangeNotifierProvider.value(
    value: cart,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('ProductCard OOS disables add-to-cart for shopper', (
    tester,
  ) async {
    final cart = CartController();
    final product = _product(id: 'oos', stock: 0);

    await tester.pumpWidget(
      _harness(
        cart: cart,
        child: ProductCard(
          product: product,
          canManage: false,
          canDelete: false,
          canShop: true,
        ),
      ),
    );

    expect(find.text('Hết hàng'), findsOneWidget);
    expect(find.byTooltip('Không thể mua'), findsOneWidget);

    // Disabled add control must not add to cart
    await tester.tap(find.byIcon(Icons.add_shopping_cart_rounded));
    await tester.pump();
    expect(cart.isEmpty, isTrue);
  });

  testWidgets('ProductCard add-to-cart works when purchasable', (tester) async {
    final cart = CartController();
    final product = _product(id: 'ok', stock: 3);

    await tester.pumpWidget(
      _harness(
        cart: cart,
        child: ProductCard(
          product: product,
          canManage: false,
          canDelete: false,
          canShop: true,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add_shopping_cart_rounded));
    await tester.pump();
    expect(cart.totalQuantity, 1);
  });
}
