import 'package:hive_flutter/hive_flutter.dart';

import '../../core/utils/password_hash.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

class LocalDatabase {
  LocalDatabase._({
    required Box<dynamic> usersBox,
    required Box<dynamic> productsBox,
    required Box<dynamic> ordersBox,
  }) : _usersBox = usersBox,
       _productsBox = productsBox,
       _ordersBox = ordersBox;

  static const _usersBoxName = 'users';
  static const _productsBoxName = 'products';
  static const _ordersBoxName = 'orders';

  final Box<dynamic> _usersBox;
  final Box<dynamic> _productsBox;
  final Box<dynamic> _ordersBox;

  static Future<LocalDatabase> open() async {
    await Hive.initFlutter();
    final database = LocalDatabase._(
      usersBox: await Hive.openBox<dynamic>(_usersBoxName),
      productsBox: await Hive.openBox<dynamic>(_productsBoxName),
      ordersBox: await Hive.openBox<dynamic>(_ordersBoxName),
    );
    await database._seedUsersIfNeeded();
    await database._seedProductsIfNeeded();
    return database;
  }

  Future<void> saveUser(AppUser user) async {
    await _usersBox.put(_emailKey(user.email), user.toMap());
  }

  AppUser? getUserByEmail(String email) {
    final raw = _usersBox.get(_emailKey(email));
    final map = _asMap(raw);
    return map == null ? null : AppUser.fromMap(map);
  }

  bool emailExists(String email) {
    return _usersBox.containsKey(_emailKey(email));
  }

  List<Product> getProducts() {
    final products =
        _productsBox.values
            .map(_asMap)
            .whereType<Map<dynamic, dynamic>>()
            .map(Product.fromMap)
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return products;
  }

  Product? getProduct(String id) {
    final raw = _productsBox.get(id);
    final map = _asMap(raw);
    return map == null ? null : Product.fromMap(map);
  }

  Future<void> saveProduct(Product product) async {
    await _productsBox.put(product.id, product.toMap());
  }

  Future<void> deleteProduct(String id) async {
    await _productsBox.delete(id);
  }

  List<OrderModel> getOrders() {
    final orders =
        _ordersBox.values
            .map(_asMap)
            .whereType<Map<dynamic, dynamic>>()
            .map(OrderModel.fromMap)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return orders;
  }

  Future<void> saveOrder(OrderModel order) async {
    await _ordersBox.put(order.id, order.toMap());
  }

  Future<void> _seedUsersIfNeeded() async {
    final now = DateTime.now();
    final users = [
      AppUser(
        id: 'seed-admin',
        fullName: 'Admin Store',
        email: 'admin@store.local',
        passwordHash: hashPassword('123456'),
        role: AppRole.admin,
        createdAt: now,
      ),
      AppUser(
        id: 'seed-manager',
        fullName: 'Manager Store',
        email: 'manager@store.local',
        passwordHash: hashPassword('123456'),
        role: AppRole.manager,
        createdAt: now,
      ),
      AppUser(
        id: 'seed-customer',
        fullName: 'Customer Demo',
        email: 'customer@store.local',
        passwordHash: hashPassword('123456'),
        role: AppRole.customer,
        createdAt: now,
      ),
    ];

    for (final user in users) {
      if (!emailExists(user.email)) {
        await saveUser(user);
      }
    }
  }

  Future<void> _seedProductsIfNeeded() async {
    if (_productsBox.isNotEmpty) {
      return;
    }

    final now = DateTime.now();
    final products = [
      Product(
        id: 'seed-smart-watch',
        name: 'Orbit Smart Watch',
        description: 'Đồng hồ theo dõi sức khỏe, pin 7 ngày, chống nước IP68.',
        price: 1890000,
        imageUrl:
            'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=900&q=80',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 'seed-headphone',
        name: 'Breeze ANC Headphone',
        description: 'Tai nghe chống ồn chủ động, âm trầm chắc, sạc USB-C.',
        price: 2490000,
        imageUrl:
            'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=900&q=80',
        createdAt: now.subtract(const Duration(minutes: 4)),
        updatedAt: now.subtract(const Duration(minutes: 4)),
      ),
      Product(
        id: 'seed-camera',
        name: 'Nova Pocket Camera',
        description: 'Máy ảnh nhỏ gọn cho du lịch, quay 4K và kết nối Wi-Fi.',
        price: 5690000,
        imageUrl:
            'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=900&q=80',
        createdAt: now.subtract(const Duration(minutes: 8)),
        updatedAt: now.subtract(const Duration(minutes: 8)),
      ),
      Product(
        id: 'seed-backpack',
        name: 'Metro Work Backpack',
        description: 'Balo laptop 15 inch, nhiều ngăn, vải kháng nước.',
        price: 890000,
        imageUrl:
            'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?auto=format&fit=crop&w=900&q=80',
        createdAt: now.subtract(const Duration(minutes: 12)),
        updatedAt: now.subtract(const Duration(minutes: 12)),
      ),
    ];

    for (final product in products) {
      await saveProduct(product);
    }
  }

  static String _emailKey(String email) => email.trim().toLowerCase();

  static Map<dynamic, dynamic>? _asMap(dynamic raw) {
    if (raw is Map<dynamic, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<dynamic, dynamic>.from(raw);
    }
    return null;
  }
}
