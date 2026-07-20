import 'package:flutter_test/flutter_test.dart';
import 'package:product_management_cart_app/data/models/product_model.dart';
import 'package:product_management_cart_app/state/cart_controller.dart';

void main() {
  test('cart calculates quantity and total price', () {
    final controller = CartController();
    final product = Product(
      id: 'p1',
      sku: 'SKU-TEST-001',
      name: 'Test product',
      description: 'A product for cart testing.',
      category: ProductCategory.other,
      price: 120000,
      stockQuantity: 3,
      status: ProductStatus.active,
      imageUrl: '',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    controller.addProduct(product);
    controller.addProduct(product);

    expect(controller.totalQuantity, 2);
    expect(controller.totalPrice, 240000);

    controller.decrement(product.id);
    expect(controller.totalQuantity, 1);

    controller.remove(product.id);
    expect(controller.isEmpty, isTrue);
  });

  test('cart rejects non-purchasable draft products', () {
    final controller = CartController();
    final draft = Product(
      id: 'draft-1',
      sku: 'SKU-DRAFT',
      name: 'Draft item',
      description: 'Not for sale',
      category: ProductCategory.other,
      price: 10000,
      stockQuantity: 5,
      status: ProductStatus.draft,
      imageUrl: '',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    expect(controller.addProduct(draft), isFalse);
    expect(controller.isEmpty, isTrue);
  });
}
