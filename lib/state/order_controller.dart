import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/utils/load_status.dart';
import '../data/models/cart_item.dart';
import '../data/models/coupon_model.dart';
import '../data/models/order_model.dart';
import '../data/models/user_model.dart';
import '../data/models/user_role.dart';
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
  String? _activeUserKey;

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

  /// Revenue counts paid, non-cancelled orders only.
  double get totalRevenue {
    return _orders
        .where((o) => o.countsTowardRevenue)
        .fold<double>(0, (total, order) => total + order.totalAmount);
  }

  double get filteredRevenue {
    return filteredOrders
        .where((o) => o.countsTowardRevenue)
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

  /// Checkout is handled by a callable Cloud Function so live product price,
  /// stock, coupon usage, order write and seller fulfillments commit together.
  Future<OrderModel> checkout({
    required AppUser user,
    required List<CartItem> items,
    String customerName = '',
    String phone = '',
    String shippingAddress = '',
    String note = '',
    PaymentMethod paymentMethod = PaymentMethod.cashOnDelivery,
    String couponCode = '',
  }) async {
    return _database.placeOrderViaFunction(
      items: items
          .map(
            (item) => <String, Object?>{
              'productId': item.product.id,
              'quantity': item.quantity,
            },
          )
          .toList(),
      customerName: customerName.trim().isEmpty
          ? user.fullName.trim()
          : customerName.trim(),
      phone: phone.trim(),
      shippingAddress: shippingAddress.trim(),
      note: note.trim(),
      paymentMethod: paymentMethod,
      couponCode: Coupon.normalizeCode(couponCode),
    );
  }

  Future<AppliedCoupon> previewCoupon({
    required String code,
    required double subtotal,
  }) {
    return _database.previewCoupon(code: code, subtotal: subtotal);
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
    final isStaff = actor.canViewRevenue;
    if (!OrderTransitions.isValidTransition(
      from: order.status,
      to: OrderStatus.cancelled,
      isStaff: isStaff,
    )) {
      throw StateError('Không thể hủy đơn ở trạng thái ${order.status.label}.');
    }
    if (!isStaff &&
        order.userEmail.trim().toLowerCase() !=
            actor.email.trim().toLowerCase()) {
      throw StateError('Bạn không có quyền hủy đơn này.');
    }

    _updating = true;
    notifyListeners();
    try {
      return await _database.cancelOrderAtomic(
        order: order,
        actorEmail: actor.email,
        note: isStaff ? 'Cửa hàng hủy đơn' : 'Khách hủy đơn',
      );
    } finally {
      _updating = false;
      notifyListeners();
    }
  }

  Future<OrderModel> markPaid(OrderModel order, AppUser staff) async {
    if (!staff.canManageOrders) {
      throw StateError('Bạn không có quyền xác nhận thanh toán.');
    }
    if (!order.canStaffMarkPaid) {
      throw StateError('Không thể xác nhận thanh toán cho đơn này.');
    }

    final updated = order.copyWith(paymentStatus: PaymentStatus.paid);
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

  Future<OrderModel> refundPayment(OrderModel order, AppUser staff) async {
    if (!staff.canManageOrders) {
      throw StateError('Bạn không có quyền hoàn tiền.');
    }
    if (!order.canStaffRefund) {
      throw StateError('Chỉ hoàn tiền cho đơn đã thanh toán và đã hủy.');
    }

    final updated = order.copyWith(paymentStatus: PaymentStatus.refunded);
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

  /// Count of orders in a status (for staff board badges).
  int countByStatus(OrderStatus status) {
    return _orders.where((o) => o.status == status).length;
  }

  List<OrderModel> ordersByStatus(OrderStatus? status, {String query = ''}) {
    final q = query.trim().toLowerCase();
    return _orders.where((o) {
      if (status != null && o.status != status) return false;
      if (q.isEmpty) return true;
      return o.id.toLowerCase().contains(q) ||
          o.userEmail.toLowerCase().contains(q) ||
          o.customerName.toLowerCase().contains(q) ||
          o.phone.contains(q);
    }).toList();
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
        return 'Khách xác nhận đã nhận';
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
      _activeUserKey = null;
      _orders = [];
      _filter = RevenueFilter.all;
      _statusFilter = null;
      _status = LoadStatus.idle;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    final userKey = '${user.email.trim().toLowerCase()}|${user.role.key}';
    if (_activeUserKey != userKey) {
      _activeUserKey = userKey;
      _filter = RevenueFilter.all;
      _statusFilter = null;
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
