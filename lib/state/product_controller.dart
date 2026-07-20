import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/product_model.dart';
import '../data/services/firestore_database.dart';
import 'auth_controller.dart';

enum ProductSort { newest, priceAsc, priceDesc }

class ProductController extends ChangeNotifier {
  ProductController(this._database, this._authController) {
    _authController.addListener(_watchProductsForCurrentUser);
    _watchProductsForCurrentUser();
  }

  final FirestoreDatabase _database;
  final AuthController _authController;
  StreamSubscription<List<Product>>? _subscription;

  List<Product> _products = [];
  String _searchQuery = '';
  ProductSort _sort = ProductSort.newest;
  ProductCategory? _category;

  List<Product> get products => List.unmodifiable(_products);
  String get searchQuery => _searchQuery;
  ProductSort get sort => _sort;
  ProductCategory? get category => _category;

  List<Product> get visibleProducts {
    final query = _searchQuery.trim().toLowerCase();
    final items = _products.where((product) {
      if (_category != null && product.category != _category) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }
      return product.name.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query) ||
          product.sku.toLowerCase().contains(query);
    }).toList();

    switch (_sort) {
      case ProductSort.priceAsc:
        items.sort((a, b) => a.price.compareTo(b.price));
      case ProductSort.priceDesc:
        items.sort((a, b) => b.price.compareTo(a.price));
      case ProductSort.newest:
        items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }

    return items;
  }

  Product? findById(String id) {
    for (final product in _products) {
      if (product.id == id) {
        return product;
      }
    }
    return null;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSort(ProductSort sort) {
    _sort = sort;
    notifyListeners();
  }

  void setCategory(ProductCategory? category) {
    _category = category;
    notifyListeners();
  }

  Future<Product> addProduct({
    required String sku,
    required String name,
    required String description,
    required ProductCategory category,
    required double price,
    required int stockQuantity,
    required ProductStatus status,
    required String imageUrl,
  }) async {
    final now = DateTime.now();
    final product = Product(
      id: 'product-${now.microsecondsSinceEpoch}',
      sku: sku.trim().isEmpty ? _createSku(now) : sku.trim().toUpperCase(),
      name: name.trim(),
      description: description.trim(),
      category: category,
      price: price,
      stockQuantity: stockQuantity,
      status: status,
      imageUrl: imageUrl.trim(),
      createdAt: now,
      updatedAt: now,
    );

    await _database.saveProduct(product);
    return product;
  }

  Future<void> updateProduct(Product product) async {
    await _database.saveProduct(product.copyWith(updatedAt: DateTime.now()));
  }

  Future<void> deleteProduct(String id) async {
    await _database.deleteProduct(id);
  }

  Future<bool> reduceStock(Map<String, int> quantitiesByProductId) async {
    return _database.reduceStock(quantitiesByProductId);
  }

  @override
  void dispose() {
    _authController.removeListener(_watchProductsForCurrentUser);
    _subscription?.cancel();
    super.dispose();
  }

  void _watchProductsForCurrentUser() {
    _subscription?.cancel();
    if (!_authController.isAuthenticated) {
      _products = [];
      notifyListeners();
      return;
    }

    _subscription = _database.watchProducts().listen((products) {
      _products = products;
      notifyListeners();
    });
  }

  static String _createSku(DateTime now) {
    return 'SKU-${now.microsecondsSinceEpoch.toString().substring(8)}';
  }
}
