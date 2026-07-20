import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/utils/load_status.dart';
import '../data/models/product_model.dart';
import '../data/services/firestore_database.dart';
import 'auth_controller.dart';
import 'product_filters.dart';

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
  ProductStatus? _statusFilter;
  LoadStatus _status = LoadStatus.idle;
  String? _errorMessage;

  List<Product> get products => List.unmodifiable(_products);
  String get searchQuery => _searchQuery;
  ProductSort get sort => _sort;
  ProductCategory? get category => _category;
  ProductStatus? get statusFilter => _statusFilter;
  LoadStatus get status => _status;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == LoadStatus.loading;
  bool get hasError => _status == LoadStatus.error;
  bool get isReady => _status == LoadStatus.ready;

  /// Filtered list using design §5.1 pipeline.
  List<Product> get visibleProducts {
    final canManage = _authController.currentUser?.canManageProducts ?? false;
    return applyProductFilters(
      products: _products,
      canManageProducts: canManage,
      category: _category,
      statusFilter: _statusFilter,
      searchQuery: _searchQuery,
      sort: _sort,
    );
  }

  Product? findById(String id) {
    for (final product in _products) {
      if (product.id == id) {
        return product;
      }
    }
    return null;
  }

  /// UX-only storefront visibility for the signed-in role.
  bool isVisibleToCurrentUser(Product product) {
    final user = _authController.currentUser;
    if (user == null) {
      return false;
    }
    return isProductVisibleToRole(
      product: product,
      canManageProducts: user.canManageProducts,
    );
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

  /// Staff-only filter; ignored for customers in the pipeline.
  void setStatusFilter(ProductStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  /// Re-subscribe to the products stream after an error or manual refresh.
  void retry() {
    _watchProductsForCurrentUser();
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
      _status = LoadStatus.idle;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _status = LoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    _subscription = _database.watchProducts().listen(
      (products) {
        _products = products;
        _status = LoadStatus.ready;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        _status = LoadStatus.error;
        _errorMessage =
            'Không thể tải sản phẩm. Kiểm tra kết nối mạng và thử lại.';
        notifyListeners();
      },
    );
  }

  static String _createSku(DateTime now) {
    return 'SKU-${now.microsecondsSinceEpoch.toString().substring(8)}';
  }
}
