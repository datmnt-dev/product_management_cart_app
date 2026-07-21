import 'order_model.dart';

class SellerFulfillment {
  const SellerFulfillment({
    required this.id,
    required this.orderId,
    required this.sellerId,
    required this.sellerName,
    required this.customerEmail,
    required this.customerName,
    required this.phone,
    required this.shippingAddress,
    required this.items,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  final String id,
      orderId,
      sellerId,
      sellerName,
      customerEmail,
      customerName,
      phone,
      shippingAddress;
  final List<OrderLine> items;
  final OrderStatus status;
  final DateTime createdAt, updatedAt;
  double get totalAmount => items.fold(0, (sum, item) => sum + item.totalPrice);
  Map<String, dynamic> toMap() => {
    'id': id,
    'orderId': orderId,
    'sellerId': sellerId,
    'sellerName': sellerName,
    'customerEmail': customerEmail,
    'customerName': customerName,
    'phone': phone,
    'shippingAddress': shippingAddress,
    'items': items.map((item) => item.toMap()).toList(),
    'status': status.key,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
  factory SellerFulfillment.fromMap(Map<String, dynamic> map) =>
      SellerFulfillment(
        id: map['id']?.toString() ?? '',
        orderId: map['orderId']?.toString() ?? '',
        sellerId: map['sellerId']?.toString() ?? '',
        sellerName: map['sellerName']?.toString() ?? '',
        customerEmail: map['customerEmail']?.toString() ?? '',
        customerName: map['customerName']?.toString() ?? '',
        phone: map['phone']?.toString() ?? '',
        shippingAddress: map['shippingAddress']?.toString() ?? '',
        items: (map['items'] as List<dynamic>? ?? [])
            .map((item) => OrderLine.fromMap(item as Map<dynamic, dynamic>))
            .toList(),
        status: OrderStatusX.fromKey(map['status']?.toString()),
        createdAt: OrderModel.dateFrom(map['createdAt']),
        updatedAt: OrderModel.dateFrom(map['updatedAt']),
      );
}
