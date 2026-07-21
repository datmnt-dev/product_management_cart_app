import '../../data/models/order_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/seller_fulfillment.dart';

/// Read-only shop metrics derived from the seller's own documents.
class SellerDashboardMetrics {
  const SellerDashboardMetrics({
    required this.productCount,
    required this.activeProductCount,
    required this.lowStockProducts,
    required this.outOfStockProducts,
    required this.awaitingDispatchCount,
    required this.shippingCount,
    required this.totalFulfillmentValue,
    required this.itemCount,
  });

  final int productCount;
  final int activeProductCount;
  final List<Product> lowStockProducts;
  final List<Product> outOfStockProducts;
  final int awaitingDispatchCount;
  final int shippingCount;
  final double totalFulfillmentValue;
  final int itemCount;

  factory SellerDashboardMetrics.fromData({
    required List<Product> products,
    required List<SellerFulfillment> fulfillments,
  }) {
    final lowStock =
        products
            .where(
              (product) =>
                  product.isActive &&
                  product.stockQuantity > 0 &&
                  product.stockQuantity <= 5,
            )
            .toList()
          ..sort((a, b) => a.stockQuantity.compareTo(b.stockQuantity));
    final outOfStock =
        products
            .where((product) => product.isActive && product.stockQuantity <= 0)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    final awaitingDispatch = fulfillments.where((fulfillment) {
      return fulfillment.status == OrderStatus.placed ||
          fulfillment.status == OrderStatus.confirmed ||
          fulfillment.status == OrderStatus.preparing;
    }).length;

    return SellerDashboardMetrics(
      productCount: products.length,
      activeProductCount: products.where((product) => product.isActive).length,
      lowStockProducts: lowStock,
      outOfStockProducts: outOfStock,
      awaitingDispatchCount: awaitingDispatch,
      shippingCount: fulfillments
          .where((fulfillment) => fulfillment.status == OrderStatus.shipping)
          .length,
      totalFulfillmentValue: fulfillments.fold(
        0,
        (total, fulfillment) => total + fulfillment.totalAmount,
      ),
      itemCount: fulfillments.fold(
        0,
        (total, fulfillment) =>
            total +
            fulfillment.items.fold(0, (sum, item) => sum + item.quantity),
      ),
    );
  }
}
