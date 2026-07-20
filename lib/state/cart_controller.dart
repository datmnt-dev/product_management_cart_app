import 'package:flutter/foundation.dart';

import '../data/models/cart_item.dart';
import '../data/models/product_model.dart';

class CartController extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => List.unmodifiable(_items.values);

  int get totalQuantity {
    return _items.values.fold<int>(0, (total, item) => total + item.quantity);
  }

  double get totalPrice {
    return _items.values.fold<double>(
      0,
      (total, item) => total + item.totalPrice,
    );
  }

  bool get isEmpty => _items.isEmpty;

  bool addProduct(Product product) {
    if (!product.canBePurchased) {
      return false;
    }

    final current = _items[product.id];
    if (current == null) {
      _items[product.id] = CartItem(product: product, quantity: 1);
    } else {
      if (current.quantity >= product.stockQuantity) {
        return false;
      }
      _items[product.id] = current.copyWith(quantity: current.quantity + 1);
    }
    notifyListeners();
    return true;
  }

  bool increment(String productId) {
    final item = _items[productId];
    if (item == null) {
      return false;
    }
    if (item.quantity >= item.product.stockQuantity) {
      return false;
    }
    _items[productId] = item.copyWith(quantity: item.quantity + 1);
    notifyListeners();
    return true;
  }

  void decrement(String productId) {
    final item = _items[productId];
    if (item == null) {
      return;
    }

    updateQuantity(productId, item.quantity - 1);
  }

  void updateQuantity(String productId, int quantity) {
    final item = _items[productId];
    if (item == null) {
      return;
    }

    if (quantity <= 0) {
      _items.remove(productId);
    } else {
      _items[productId] = item.copyWith(quantity: quantity);
    }
    notifyListeners();
  }

  void remove(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
