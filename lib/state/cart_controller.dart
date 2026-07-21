import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/cart_item.dart';
import '../data/models/product_model.dart';

/// Session cart with optional SharedPreferences persistence per user email.
class CartController extends ChangeNotifier {
  CartController({SharedPreferences? preferences}) : _prefs = preferences;

  static const _keyPrefix = 'cart_v1_';

  SharedPreferences? _prefs;
  String? _userEmail;
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

  void attachPreferences(SharedPreferences preferences) {
    _prefs = preferences;
  }

  /// Bind cart to signed-in user and restore from disk against [catalog].
  Future<void> bindUser(String? email, List<Product> catalog) async {
    final normalized = email?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      _userEmail = null;
      _items.clear();
      notifyListeners();
      return;
    }

    if (_userEmail == normalized && _items.isNotEmpty) {
      // Same user — still re-clamp against latest catalog stock.
      _rehydrateAgainstCatalog(catalog);
      notifyListeners();
      return;
    }

    _userEmail = normalized;
    _items.clear();
    await _loadFromPrefs(catalog);
    notifyListeners();
  }

  void clearForLogout() {
    final email = _userEmail;
    _items.clear();
    _userEmail = null;
    if (email != null) {
      _prefs?.remove(_storageKey(email));
    }
    notifyListeners();
  }

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
    _persist();
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
    _persist();
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
      final maxQty = item.product.stockQuantity;
      final clamped = quantity > maxQty ? maxQty : quantity;
      if (clamped <= 0) {
        _items.remove(productId);
      } else {
        _items[productId] = item.copyWith(quantity: clamped);
      }
    }
    notifyListeners();
    _persist();
  }

  void remove(String productId) {
    _items.remove(productId);
    notifyListeners();
    _persist();
  }

  void clear() {
    _items.clear();
    notifyListeners();
    _persist();
  }

  String _storageKey(String email) => '$_keyPrefix$email';

  Future<void> _loadFromPrefs(List<Product> catalog) async {
    final prefs = _prefs;
    final email = _userEmail;
    if (prefs == null || email == null) return;

    final raw = prefs.getString(_storageKey(email));
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final byId = {for (final p in catalog) p.id: p};

      for (final entry in decoded) {
        if (entry is! Map) continue;
        final id = entry['productId']?.toString() ?? '';
        final qty =
            (entry['quantity'] as num?)?.toInt() ??
            int.tryParse(entry['quantity']?.toString() ?? '') ??
            0;
        final product = byId[id];
        if (product == null || !product.canBePurchased || qty <= 0) continue;
        final clamped = qty > product.stockQuantity
            ? product.stockQuantity
            : qty;
        if (clamped <= 0) continue;
        _items[id] = CartItem(product: product, quantity: clamped);
      }
    } catch (_) {
      // Corrupt cart blob — ignore.
    }
  }

  void _rehydrateAgainstCatalog(List<Product> catalog) {
    final byId = {for (final p in catalog) p.id: p};
    final stale = <String>[];
    for (final entry in _items.entries) {
      final product = byId[entry.key];
      if (product == null || !product.canBePurchased) {
        stale.add(entry.key);
        continue;
      }
      final qty = entry.value.quantity;
      final clamped = qty > product.stockQuantity ? product.stockQuantity : qty;
      if (clamped <= 0) {
        stale.add(entry.key);
      } else {
        _items[entry.key] = CartItem(product: product, quantity: clamped);
      }
    }
    for (final id in stale) {
      _items.remove(id);
    }
    _persist();
  }

  void _persist() {
    final prefs = _prefs;
    final email = _userEmail;
    if (prefs == null || email == null) return;

    final payload = _items.values
        .map(
          (item) => {'productId': item.product.id, 'quantity': item.quantity},
        )
        .toList();
    prefs.setString(_storageKey(email), jsonEncode(payload));
  }
}
