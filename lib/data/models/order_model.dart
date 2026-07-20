import 'package:cloud_firestore/cloud_firestore.dart';

class OrderLine {
  const OrderLine({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.imageUrl,
  });

  final String productId;
  final String name;
  final double unitPrice;
  final int quantity;
  final String imageUrl;

  double get totalPrice => unitPrice * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'imageUrl': imageUrl,
    };
  }

  factory OrderLine.fromMap(Map<dynamic, dynamic> map) {
    return OrderLine(
      productId: map['productId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      unitPrice:
          (map['unitPrice'] as num?)?.toDouble() ??
          double.tryParse(map['unitPrice']?.toString() ?? '') ??
          0,
      quantity:
          (map['quantity'] as num?)?.toInt() ??
          int.tryParse(map['quantity']?.toString() ?? '') ??
          0,
      imageUrl: map['imageUrl']?.toString() ?? '',
    );
  }
}

class OrderModel {
  const OrderModel({
    required this.id,
    required this.userEmail,
    required this.items,
    required this.totalAmount,
    required this.createdAt,
  });

  final String id;
  final String userEmail;
  final List<OrderLine> items;
  final double totalAmount;
  final DateTime createdAt;

  int get totalQuantity {
    return items.fold<int>(0, (total, item) => total + item.quantity);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userEmail': userEmail,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'createdAt': createdAt,
    };
  }

  factory OrderModel.fromMap(Map<dynamic, dynamic> map) {
    final rawItems = map['items'];
    final lines = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map((item) => OrderLine.fromMap(item))
              .toList()
        : <OrderLine>[];

    return OrderModel(
      id: map['id']?.toString() ?? '',
      userEmail: map['userEmail']?.toString() ?? '',
      items: lines,
      totalAmount:
          (map['totalAmount'] as num?)?.toDouble() ??
          double.tryParse(map['totalAmount']?.toString() ?? '') ??
          0,
      createdAt: _dateFrom(map['createdAt']),
    );
  }

  static DateTime _dateFrom(dynamic raw) {
    if (raw is Timestamp) {
      return raw.toDate();
    }
    if (raw is DateTime) {
      return raw;
    }
    return DateTime.tryParse(raw?.toString() ?? '') ?? DateTime.now();
  }
}
