import 'package:flutter_test/flutter_test.dart';
import 'package:product_management_cart_app/data/models/order_model.dart';
import 'package:product_management_cart_app/data/models/product_model.dart';
import 'package:product_management_cart_app/data/models/seller_fulfillment.dart';
import 'package:product_management_cart_app/features/seller/seller_dashboard_metrics.dart';

void main() {
  final now = DateTime(2026, 7, 21);

  Product product(String id, int stock) => Product(
    id: id,
    sku: id,
    name: id,
    description: '',
    category: ProductCategory.other,
    price: 100,
    stockQuantity: stock,
    status: ProductStatus.active,
    imageUrl: '',
    createdAt: now,
    updatedAt: now,
    sellerId: 'seller-1',
    sellerName: 'Shop A',
  );

  SellerFulfillment fulfillment(OrderStatus status, int quantity) =>
      SellerFulfillment(
        id: 'f-$quantity-${status.key}',
        orderId: 'o-$quantity',
        sellerId: 'seller-1',
        sellerName: 'Shop A',
        customerEmail: '',
        customerName: '',
        phone: '',
        shippingAddress: '',
        status: status,
        createdAt: now,
        updatedAt: now,
        items: [
          OrderLine(
            productId: 'p',
            name: 'Item',
            unitPrice: 100,
            quantity: quantity,
            imageUrl: '',
          ),
        ],
      );

  test('summarizes stock and active seller fulfillment work', () {
    final metrics = SellerDashboardMetrics.fromData(
      products: [product('low', 2), product('out', 0), product('healthy', 10)],
      fulfillments: [
        fulfillment(OrderStatus.placed, 2),
        fulfillment(OrderStatus.shipping, 3),
      ],
    );

    expect(metrics.productCount, 3);
    expect(metrics.activeProductCount, 3);
    expect(metrics.lowStockProducts.single.id, 'low');
    expect(metrics.outOfStockProducts.single.id, 'out');
    expect(metrics.awaitingDispatchCount, 1);
    expect(metrics.shippingCount, 1);
    expect(metrics.itemCount, 5);
    expect(metrics.totalFulfillmentValue, 500);
  });
}
