import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/utils/load_status.dart';
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
  OrderStatus? _statusFilter;
  LoadStatus _status = LoadStatus.idle;
  String? _errorMessage;
  bool _updating = false;

  List<OrderModel> get orders => List.unmodifiable(_orders);
  RevenueFilter get filter => _filter;
  OrderStatus? get statusFilter => _statusFilter;
  LoadStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isUpdating => _updating;

  bool get isLoading => _status == LoadStatus.loading;
  bool get hasError => _status == LoadStatus.error;
  bool get isReady => _status == LoadStatus.ready;

  List<OrderModel> get filteredOrders {
    return _orders.where((order) {
      if (!_matchesFilter(order.createdAt)) return false;
      if (_statusFilter != null && order.status != _statusFilter) return false;
      return true;
    }).toList();
  }

  /// Revenue excludes cancelled orders.
  double get totalRevenue {
    return _orders
        .where((o) => o.status.countsTowardRevenue)
        .fold<double>(0, (total, order) => total + order.totalAmount);
  }

  double get filteredRevenue {
    return filteredOrders
        .where((o) => o.status.countsTowardRevenue)
        .fold<double>(0, (total, order) => total + order.totalAmount);
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

  void setStatusFilter(OrderStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  /// Re-subscribe to the orders stream after an error or manual refresh.
  void retry() {
    _watchOrdersForCurrentUser();
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
      updatedAt: now,
      status: OrderStatus.placed,
      statusHistory: [
        OrderStatusEvent(
          status: OrderStatus.placed,
          at: now,
          byEmail: user.email,
          note: 'Khách đã gửi đơn hàng',
        ),
      ],
    );

    await _database.saveOrder(order);
    return order;
  }

  /// Staff or customer status transition with validation.
  Future<OrderModel> updateStatus({
    required OrderModel order,
    required OrderStatus next,
    required AppUser actor,
    String note = '',
  }) async {
    final isStaff = actor.canViewRevenue;
    if (!OrderTransitions.isValidTransition(
      from: order.status,
      to: next,
      isStaff: isStaff,
    )) {
      throw StateError(
        'Không thể chuyển trạng thái từ ${order.status.label} sang ${next.label}.',
      );
    }

    // Customer may only touch own orders.
    if (!isStaff &&
        order.userEmail.trim().toLowerCase() !=
            actor.email.trim().toLowerCase()) {
      throw StateError('Bạn không có quyền cập nhật đơn này.');
    }

    final updated = order.withStatusTransition(
      next: next,
      byEmail: actor.email,
      note: note.isEmpty ? _defaultNote(next, isStaff: isStaff) : note,
    );

    _updating = true;
    notifyListeners();
    try {
      await _database.saveOrder(updated);
      return updated;
    } finally {
      _updating = false;
      notifyListeners();
    }
  }

  Future<OrderModel> advanceStaff(OrderModel order, AppUser staff) async {
    final next = order.status.nextStaffStatus;
    if (next == null) {
      throw StateError('Đơn đã ở trạng thái cuối, không thể tiến tiếp.');
    }
    return updateStatus(
      order: order,
      next: next,
      actor: staff,
      note: order.status.nextStaffActionLabel ?? '',
    );
  }

  Future<OrderModel> cancelOrder(OrderModel order, AppUser actor) async {
    return updateStatus(
      order: order,
      next: OrderStatus.cancelled,
      actor: actor,
      note: actor.canViewRevenue
          ? 'Cửa hàng hủy đơn'
          : 'Khách hủy đơn',
    );
  }

  Future<OrderModel> customerConfirmReceived(
    OrderModel order,
    AppUser customer,
  ) async {
    return updateStatus(
      order: order,
      next: OrderStatus.delivered,
      actor: customer,
      note: 'Khách xác nhận đã nhận hàng',
    );
  }

  static String _defaultNote(OrderStatus status, {required bool isStaff}) {
    switch (status) {
      case OrderStatus.placed:
        return 'Đã gửi đơn';
      case OrderStatus.confirmed:
        return 'Shop xác nhận đã nhận đơn';
      case OrderStatus.preparing:
        return 'Shop bắt đầu chuẩn bị hàng';
      case OrderStatus.shipping:
        return 'Shop bàn giao vận chuyển';
      case OrderStatus.delivered:
        return isStaff ? 'Shop xác nhận đã giao' : 'Khách xác nhận đã nhận';
      case OrderStatus.cancelled:
        return 'Đơn đã hủy';
    }
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
      _status = LoadStatus.idle;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _status = LoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    _subscription = _database
        .watchOrders(userEmail: user.canViewRevenue ? null : user.email)
        .listen(
          (orders) {
            _orders = orders;
            _status = LoadStatus.ready;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (Object error, StackTrace stackTrace) {
            _status = LoadStatus.error;
            _errorMessage =
                'Không thể tải đơn hàng. Kiểm tra kết nối mạng và thử lại.';
            notifyListeners();
          },
        );
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
