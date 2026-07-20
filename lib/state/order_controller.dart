import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/cart_item.dart';
import '../data/models/order_model.dart';
import '../data/models/user_model.dart';
import '../data/services/firestore_database.dart';
import 'auth_controller.dart';

enum RevenueFilter { all, day, month, year }

class OrderController extends ChangeNotifier {
  OrderController(this._database, this._authController) {
    _authController.addListener(_watchOrdersForCurrentUser);
    _watchOrdersForCurrentUser();
  }

  final FirestoreDatabase _database;
  final AuthController _authController;
  StreamSubscription<List<OrderModel>>? _subscription;

  List<OrderModel> _orders = [];
  RevenueFilter _filter = RevenueFilter.all;

  List<OrderModel> get orders => List.unmodifiable(_orders);
  RevenueFilter get filter => _filter;

  List<OrderModel> get filteredOrders {
    return _orders.where((order) => _matchesFilter(order.createdAt)).toList();
  }

  double get totalRevenue {
    return _orders.fold<double>(0, (total, order) => total + order.totalAmount);
  }

  double get filteredRevenue {
    return filteredOrders.fold<double>(
      0,
      (total, order) => total + order.totalAmount,
    );
  }

  List<OrderModel> ordersForEmail(String email) {
    final normalized = email.trim().toLowerCase();
    return _orders.where((order) {
      return order.userEmail.trim().toLowerCase() == normalized;
    }).toList();
  }

  void setFilter(RevenueFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  Future<OrderModel> checkout({
    required AppUser user,
    required List<CartItem> items,
  }) async {
    final now = DateTime.now();
    final orderItems = items.map((item) {
      return OrderLine(
        productId: item.product.id,
        name: item.product.name,
        unitPrice: item.product.price,
        quantity: item.quantity,
        imageUrl: item.product.imageUrl,
      );
    }).toList();

    final order = OrderModel(
      id: 'order-${now.microsecondsSinceEpoch}',
      userEmail: user.email,
      items: orderItems,
      totalAmount: orderItems.fold<double>(
        0,
        (total, item) => total + item.totalPrice,
      ),
      createdAt: now,
    );

    await _database.saveOrder(order);
    return order;
  }

  @override
  void dispose() {
    _authController.removeListener(_watchOrdersForCurrentUser);
    _subscription?.cancel();
    super.dispose();
  }

  void _watchOrdersForCurrentUser() {
    _subscription?.cancel();
    final user = _authController.currentUser;
    if (user == null) {
      _orders = [];
      notifyListeners();
      return;
    }

    _subscription = _database
        .watchOrders(userEmail: user.canViewRevenue ? null : user.email)
        .listen((orders) {
          _orders = orders;
          notifyListeners();
        });
  }

  bool _matchesFilter(DateTime date) {
    final now = DateTime.now();
    switch (_filter) {
      case RevenueFilter.all:
        return true;
      case RevenueFilter.day:
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      case RevenueFilter.month:
        return date.year == now.year && date.month == now.month;
      case RevenueFilter.year:
        return date.year == now.year;
    }
  }
}
