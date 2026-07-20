import 'package:flutter/foundation.dart';

import '../data/models/product_model.dart';
import '../data/services/local_database.dart';

enum ProductSort { newest, priceAsc, priceDesc }

class ProductController extends ChangeNotifier {
  ProductController(this._database) {
    _products = _database.getProducts();
  }

  final LocalDatabase _database;

  List<Product> _products = [];
  String _searchQuery = '';
  ProductSort _sort = ProductSort.newest;

  List<Product> get products => List.unmodifiable(_products);
  String get searchQuery => _searchQuery;
  ProductSort get sort => _sort;

  List<Product> get visibleProducts {
    final query = _searchQuery.trim().toLowerCase();
    final items = _products.where((product) {
      if (query.isEmpty) {
        return true;
      }
      return product.name.toLowerCase().contains(query);
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

  Future<Product> addProduct({
    required String name,
    required String description,
    required double price,
    required String imageUrl,
  }) async {
    final now = DateTime.now();
    final product = Product(
      id: 'product-${now.microsecondsSinceEpoch}',
      name: name.trim(),
      description: description.trim(),
      price: price,
      imageUrl: imageUrl.trim(),
      createdAt: now,
      updatedAt: now,
    );

    await _database.saveProduct(product);
    _reload();
    return product;
  }

  Future<void> updateProduct(Product product) async {
    await _database.saveProduct(product.copyWith(updatedAt: DateTime.now()));
    _reload();
  }

  Future<void> deleteProduct(String id) async {
    await _database.deleteProduct(id);
    _reload();
  }

  void _reload() {
    _products = _database.getProducts();
    notifyListeners();
  }
}
