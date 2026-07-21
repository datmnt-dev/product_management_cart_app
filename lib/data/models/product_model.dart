import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductCategory { phone, laptop, accessory, home, other }

extension ProductCategoryX on ProductCategory {
  String get key {
    switch (this) {
      case ProductCategory.phone:
        return 'phone';
      case ProductCategory.laptop:
        return 'laptop';
      case ProductCategory.accessory:
        return 'accessory';
      case ProductCategory.home:
        return 'home';
      case ProductCategory.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case ProductCategory.phone:
        return 'Điện thoại';
      case ProductCategory.laptop:
        return 'Laptop';
      case ProductCategory.accessory:
        return 'Phụ kiện';
      case ProductCategory.home:
        return 'Gia dụng';
      case ProductCategory.other:
        return 'Khác';
    }
  }

  static ProductCategory fromKey(String? key) {
    switch (key) {
      case 'phone':
        return ProductCategory.phone;
      case 'laptop':
        return ProductCategory.laptop;
      case 'accessory':
        return ProductCategory.accessory;
      case 'home':
        return ProductCategory.home;
      case 'other':
      default:
        return ProductCategory.other;
    }
  }
}

enum ProductStatus { active, draft, archived }

extension ProductStatusX on ProductStatus {
  String get key {
    switch (this) {
      case ProductStatus.active:
        return 'active';
      case ProductStatus.draft:
        return 'draft';
      case ProductStatus.archived:
        return 'archived';
    }
  }

  String get label {
    switch (this) {
      case ProductStatus.active:
        return 'Đang bán';
      case ProductStatus.draft:
        return 'Bản nháp';
      case ProductStatus.archived:
        return 'Ngừng bán';
    }
  }

  static ProductStatus fromKey(String? key) {
    switch (key) {
      case 'draft':
        return ProductStatus.draft;
      case 'archived':
        return ProductStatus.archived;
      case 'active':
      default:
        return ProductStatus.active;
    }
  }
}

class Product {
  const Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.stockQuantity,
    required this.status,
    required this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.sellerId = '',
    this.sellerName = '',
  });

  final String id;
  final String sku;
  final String name;
  final String description;
  final ProductCategory category;
  final double price;
  final int stockQuantity;
  final ProductStatus status;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String sellerId;
  final String sellerName;

  bool get hasImage => imageUrl.trim().isNotEmpty;
  bool get isActive => status == ProductStatus.active;
  bool get isInStock => stockQuantity > 0;
  bool get canBePurchased => isActive && isInStock;

  Product copyWith({
    String? id,
    String? sku,
    String? name,
    String? description,
    ProductCategory? category,
    double? price,
    int? stockQuantity,
    ProductStatus? status,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? sellerId,
    String? sellerName,
  }) {
    return Product(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sku': sku,
      'name': name,
      'description': description,
      'category': category.key,
      'price': price,
      'stockQuantity': stockQuantity,
      'status': status.key,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'sellerId': sellerId,
      'sellerName': sellerName,
    };
  }

  factory Product.fromMap(Map<dynamic, dynamic> map) {
    return Product(
      id: map['id']?.toString() ?? '',
      sku: map['sku']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      category: ProductCategoryX.fromKey(map['category']?.toString()),
      price:
          (map['price'] as num?)?.toDouble() ??
          double.tryParse(map['price']?.toString() ?? '') ??
          0,
      stockQuantity:
          (map['stockQuantity'] as num?)?.toInt() ??
          int.tryParse(map['stockQuantity']?.toString() ?? '') ??
          0,
      status: ProductStatusX.fromKey(map['status']?.toString()),
      imageUrl: map['imageUrl']?.toString() ?? '',
      createdAt: _dateFrom(map['createdAt']),
      updatedAt: _dateFrom(map['updatedAt']),
      sellerId: map['sellerId']?.toString() ?? '',
      sellerName: map['sellerName']?.toString() ?? '',
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
