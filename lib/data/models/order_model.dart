import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Lifecycle of a store order.
///
/// ```
/// placed → confirmed → preparing → shipping → delivered
///    ↘ cancelled (from placed / confirmed)
///
/// Staff owns the operational steps up to `shipping`; the customer confirms
/// receipt by moving `shipping` to `delivered`.
/// ```
enum OrderStatus {
  placed,
  confirmed,
  preparing,
  shipping,
  delivered,
  cancelled,
}

extension OrderStatusX on OrderStatus {
  String get key {
    switch (this) {
      case OrderStatus.placed:
        return 'placed';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.shipping:
        return 'shipping';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.placed:
        return 'Đã gửi đơn';
      case OrderStatus.confirmed:
        return 'Shop đã nhận đơn';
      case OrderStatus.preparing:
        return 'Đang chuẩn bị';
      case OrderStatus.shipping:
        return 'Đang giao hàng';
      case OrderStatus.delivered:
        return 'Khách đã nhận / hoàn thành';
      case OrderStatus.cancelled:
        return 'Đã hủy';
    }
  }

  String get shortLabel {
    switch (this) {
      case OrderStatus.placed:
        return 'Đã gửi';
      case OrderStatus.confirmed:
        return 'Shop nhận';
      case OrderStatus.preparing:
        return 'Chuẩn bị';
      case OrderStatus.shipping:
        return 'Đang giao';
      case OrderStatus.delivered:
        return 'Khách nhận';
      case OrderStatus.cancelled:
        return 'Đã hủy';
    }
  }

  String get description {
    switch (this) {
      case OrderStatus.placed:
        return 'Khách đã đặt và gửi đơn. Chờ cửa hàng xác nhận.';
      case OrderStatus.confirmed:
        return 'Cửa hàng đã xác nhận nhận đơn.';
      case OrderStatus.preparing:
        return 'Cửa hàng đang đóng gói / chuẩn bị hàng.';
      case OrderStatus.shipping:
        return 'Đơn đang trên đường giao đến khách.';
      case OrderStatus.delivered:
        return 'Khách đã xác nhận nhận hàng. Đơn hoàn tất.';
      case OrderStatus.cancelled:
        return 'Đơn đã bị hủy.';
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.placed:
        return Icons.send_outlined;
      case OrderStatus.confirmed:
        return Icons.storefront_outlined;
      case OrderStatus.preparing:
        return Icons.inventory_2_outlined;
      case OrderStatus.shipping:
        return Icons.local_shipping_outlined;
      case OrderStatus.delivered:
        return Icons.check_circle_outline;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.placed:
        return const Color(0xFF2563EB);
      case OrderStatus.confirmed:
        return const Color(0xFF0D5C58);
      case OrderStatus.preparing:
        return const Color(0xFFD97706);
      case OrderStatus.shipping:
        return const Color(0xFF7C3AED);
      case OrderStatus.delivered:
        return const Color(0xFF16A34A);
      case OrderStatus.cancelled:
        return const Color(0xFFEF4444);
    }
  }

  bool get isTerminal =>
      this == OrderStatus.delivered || this == OrderStatus.cancelled;

  bool get countsTowardRevenue => this != OrderStatus.cancelled;

  /// Next staff-driven step, if any.
  OrderStatus? get nextStaffStatus {
    switch (this) {
      case OrderStatus.placed:
        return OrderStatus.confirmed;
      case OrderStatus.confirmed:
        return OrderStatus.preparing;
      case OrderStatus.preparing:
        return OrderStatus.shipping;
      case OrderStatus.shipping:
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        return null;
    }
  }

  String? get nextStaffActionLabel {
    final next = nextStaffStatus;
    if (next == null) return null;
    switch (next) {
      case OrderStatus.confirmed:
        return 'Xác nhận đã nhận đơn';
      case OrderStatus.preparing:
        return 'Bắt đầu chuẩn bị';
      case OrderStatus.shipping:
        return 'Bàn giao vận chuyển';
      default:
        return null;
    }
  }

  static OrderStatus fromKey(String? key) {
    switch (key) {
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'shipping':
        return OrderStatus.shipping;
      case 'delivered':
      case 'completed': // legacy seed/app alias
        return OrderStatus.delivered;
      case 'cancelled':
      case 'canceled':
        return OrderStatus.cancelled;
      case 'placed':
      case 'pending':
      default:
        return OrderStatus.placed;
    }
  }
}

enum PaymentMethod { cashOnDelivery, bankTransfer, mockWallet }

extension PaymentMethodX on PaymentMethod {
  String get key {
    switch (this) {
      case PaymentMethod.cashOnDelivery:
        return 'cash_on_delivery';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
      case PaymentMethod.mockWallet:
        return 'mock_wallet';
    }
  }

  String get label {
    switch (this) {
      case PaymentMethod.cashOnDelivery:
        return 'Thanh toán khi nhận hàng';
      case PaymentMethod.bankTransfer:
        return 'Chuyển khoản ngân hàng';
      case PaymentMethod.mockWallet:
        return 'Ví điện tử giả lập';
    }
  }

  String get shortLabel {
    switch (this) {
      case PaymentMethod.cashOnDelivery:
        return 'COD';
      case PaymentMethod.bankTransfer:
        return 'Chuyển khoản';
      case PaymentMethod.mockWallet:
        return 'Ví mock';
    }
  }

  String get description {
    switch (this) {
      case PaymentMethod.cashOnDelivery:
        return 'Khách thanh toán trực tiếp khi nhận hàng.';
      case PaymentMethod.bankTransfer:
        return 'Cửa hàng xác nhận thanh toán sau khi nhận chuyển khoản.';
      case PaymentMethod.mockWallet:
        return 'Thanh toán giả lập thành công ngay khi đặt hàng.';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.cashOnDelivery:
        return Icons.payments_outlined;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance_outlined;
      case PaymentMethod.mockWallet:
        return Icons.account_balance_wallet_outlined;
    }
  }

  static PaymentMethod fromKey(String? key) {
    switch (key) {
      case 'bank_transfer':
      case 'bank':
        return PaymentMethod.bankTransfer;
      case 'mock_wallet':
      case 'wallet':
        return PaymentMethod.mockWallet;
      case 'cash_on_delivery':
      case 'cod':
      default:
        return PaymentMethod.cashOnDelivery;
    }
  }
}

enum PaymentStatus { unpaid, paid, refunded }

extension PaymentStatusX on PaymentStatus {
  String get key {
    switch (this) {
      case PaymentStatus.unpaid:
        return 'unpaid';
      case PaymentStatus.paid:
        return 'paid';
      case PaymentStatus.refunded:
        return 'refunded';
    }
  }

  String get label {
    switch (this) {
      case PaymentStatus.unpaid:
        return 'Chưa thanh toán';
      case PaymentStatus.paid:
        return 'Đã thanh toán';
      case PaymentStatus.refunded:
        return 'Đã hoàn tiền';
    }
  }

  String get shortLabel {
    switch (this) {
      case PaymentStatus.unpaid:
        return 'Chưa trả';
      case PaymentStatus.paid:
        return 'Đã trả';
      case PaymentStatus.refunded:
        return 'Hoàn tiền';
    }
  }

  Color get color {
    switch (this) {
      case PaymentStatus.unpaid:
        return const Color(0xFFD97706);
      case PaymentStatus.paid:
        return const Color(0xFF16A34A);
      case PaymentStatus.refunded:
        return const Color(0xFF7C3AED);
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentStatus.unpaid:
        return Icons.pending_actions_outlined;
      case PaymentStatus.paid:
        return Icons.verified_outlined;
      case PaymentStatus.refunded:
        return Icons.currency_exchange_outlined;
    }
  }

  static PaymentStatus fromKey(String? key) {
    switch (key) {
      case 'paid':
        return PaymentStatus.paid;
      case 'refunded':
        return PaymentStatus.refunded;
      case 'unpaid':
      case 'pending':
      default:
        return PaymentStatus.unpaid;
    }
  }
}

class OrderStatusEvent {
  const OrderStatusEvent({
    required this.status,
    required this.at,
    required this.byEmail,
    this.note = '',
  });

  final OrderStatus status;
  final DateTime at;
  final String byEmail;
  final String note;

  Map<String, dynamic> toMap() {
    return {'status': status.key, 'at': at, 'byEmail': byEmail, 'note': note};
  }

  factory OrderStatusEvent.fromMap(Map<dynamic, dynamic> map) {
    return OrderStatusEvent(
      status: OrderStatusX.fromKey(map['status']?.toString()),
      at: OrderModel.dateFrom(map['at']),
      byEmail: map['byEmail']?.toString() ?? '',
      note: map['note']?.toString() ?? '',
    );
  }
}

class OrderLine {
  const OrderLine({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.imageUrl,
    this.category = 'other',
  });

  final String productId;
  final String name;
  final double unitPrice;
  final int quantity;
  final String imageUrl;

  /// Snapshot category key at checkout (stable stats without product join).
  final String category;

  double get totalPrice => unitPrice * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'category': category,
    };
  }

  factory OrderLine.fromMap(Map<dynamic, dynamic> map) {
    return OrderLine(
      productId: map['productId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      unitPrice:
          (map['unitPrice'] as num?)?.toDouble() ??
          double.tryParse(map['unitPrice']?.toString() ?? '') ??
          0,
      quantity:
          (map['quantity'] as num?)?.toInt() ??
          int.tryParse(map['quantity']?.toString() ?? '') ??
          0,
      imageUrl: map['imageUrl']?.toString() ?? '',
      category: map['category']?.toString() ?? 'other',
    );
  }
}

class OrderModel {
  const OrderModel({
    required this.id,
    required this.userEmail,
    required this.items,
    required this.totalAmount,
    required this.createdAt,
    this.subtotalAmount,
    this.discountAmount = 0,
    this.couponCode = '',
    this.status = OrderStatus.placed,
    this.updatedAt,
    this.statusHistory = const [],
    this.stockRestored = false,
    this.customerName = '',
    this.phone = '',
    this.shippingAddress = '',
    this.note = '',
    this.paymentMethod = PaymentMethod.cashOnDelivery,
    this.paymentStatus = PaymentStatus.unpaid,
  });

  final String id;
  final String userEmail;
  final List<OrderLine> items;
  final double totalAmount;
  final double? subtotalAmount;
  final double discountAmount;
  final String couponCode;
  final DateTime createdAt;
  final OrderStatus status;
  final DateTime? updatedAt;
  final List<OrderStatusEvent> statusHistory;

  /// True after cancel restock so we never restore stock twice.
  final bool stockRestored;
  final String customerName;
  final String phone;
  final String shippingAddress;
  final String note;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;

  int get totalQuantity {
    return items.fold<int>(0, (total, item) => total + item.quantity);
  }

  DateTime get lastUpdated => updatedAt ?? createdAt;

  double get effectiveSubtotal =>
      subtotalAmount ?? totalAmount + discountAmount;

  bool get hasDiscount => couponCode.trim().isNotEmpty && discountAmount > 0;

  bool get canCustomerCancel =>
      status == OrderStatus.placed || status == OrderStatus.confirmed;

  bool get canCustomerConfirmReceived => status == OrderStatus.shipping;

  bool get hasShippingInfo =>
      phone.trim().isNotEmpty || shippingAddress.trim().isNotEmpty;

  bool get canStaffMarkPaid =>
      paymentStatus == PaymentStatus.unpaid && status != OrderStatus.cancelled;

  bool get canStaffRefund =>
      paymentStatus == PaymentStatus.paid && status == OrderStatus.cancelled;

  bool get countsTowardRevenue =>
      status != OrderStatus.cancelled && paymentStatus == PaymentStatus.paid;

  OrderModel copyWith({
    String? id,
    String? userEmail,
    List<OrderLine>? items,
    double? totalAmount,
    double? subtotalAmount,
    double? discountAmount,
    String? couponCode,
    DateTime? createdAt,
    OrderStatus? status,
    DateTime? updatedAt,
    List<OrderStatusEvent>? statusHistory,
    bool? stockRestored,
    String? customerName,
    String? phone,
    String? shippingAddress,
    String? note,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userEmail: userEmail ?? this.userEmail,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      subtotalAmount: subtotalAmount ?? this.subtotalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      couponCode: couponCode ?? this.couponCode,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      statusHistory: statusHistory ?? this.statusHistory,
      stockRestored: stockRestored ?? this.stockRestored,
      customerName: customerName ?? this.customerName,
      phone: phone ?? this.phone,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      note: note ?? this.note,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }

  /// Append a status transition (does not validate).
  OrderModel withStatusTransition({
    required OrderStatus next,
    required String byEmail,
    String note = '',
    DateTime? at,
    bool? stockRestored,
  }) {
    final when = at ?? DateTime.now();
    final event = OrderStatusEvent(
      status: next,
      at: when,
      byEmail: byEmail,
      note: note,
    );
    return copyWith(
      status: next,
      updatedAt: when,
      statusHistory: [...statusHistory, event],
      stockRestored: stockRestored,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userEmail': userEmail,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotalAmount': effectiveSubtotal,
      'discountAmount': discountAmount,
      'couponCode': couponCode,
      'totalAmount': totalAmount,
      'createdAt': createdAt,
      'status': status.key,
      'updatedAt': updatedAt ?? createdAt,
      'statusHistory': statusHistory.map((e) => e.toMap()).toList(),
      'stockRestored': stockRestored,
      'customerName': customerName,
      'phone': phone,
      'shippingAddress': shippingAddress,
      'note': note,
      'paymentMethod': paymentMethod.key,
      'paymentStatus': paymentStatus.key,
    };
  }

  factory OrderModel.fromMap(Map<dynamic, dynamic> map) {
    final rawItems = map['items'];
    final lines = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map((item) => OrderLine.fromMap(item))
              .toList()
        : <OrderLine>[];

    final rawHistory = map['statusHistory'];
    final history = rawHistory is List
        ? rawHistory
              .whereType<Map>()
              .map((e) => OrderStatusEvent.fromMap(e))
              .toList()
        : <OrderStatusEvent>[];

    final createdAt = dateFrom(map['createdAt']);
    final status = OrderStatusX.fromKey(map['status']?.toString());
    final paymentMethod = PaymentMethodX.fromKey(
      map['paymentMethod']?.toString(),
    );
    final paymentStatus = map.containsKey('paymentStatus')
        ? PaymentStatusX.fromKey(map['paymentStatus']?.toString())
        : PaymentStatus.unpaid;

    // Backfill empty history for legacy documents.
    final effectiveHistory = history.isNotEmpty
        ? history
        : [
            OrderStatusEvent(
              status: status,
              at: createdAt,
              byEmail: map['userEmail']?.toString() ?? '',
              note: 'Đơn hàng (dữ liệu cũ / seed)',
            ),
          ];

    final totalAmount =
        (map['totalAmount'] as num?)?.toDouble() ??
        double.tryParse(map['totalAmount']?.toString() ?? '') ??
        0;
    final discountAmount =
        (map['discountAmount'] as num?)?.toDouble() ??
        double.tryParse(map['discountAmount']?.toString() ?? '') ??
        0;

    return OrderModel(
      id: map['id']?.toString() ?? '',
      userEmail: map['userEmail']?.toString() ?? '',
      items: lines,
      totalAmount: totalAmount,
      subtotalAmount:
          (map['subtotalAmount'] as num?)?.toDouble() ??
          double.tryParse(map['subtotalAmount']?.toString() ?? ''),
      discountAmount: discountAmount,
      couponCode: map['couponCode']?.toString() ?? '',
      createdAt: createdAt,
      status: status,
      updatedAt: map['updatedAt'] != null
          ? dateFrom(map['updatedAt'])
          : createdAt,
      statusHistory: effectiveHistory,
      stockRestored: map['stockRestored'] == true,
      customerName: map['customerName']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      shippingAddress: map['shippingAddress']?.toString() ?? '',
      note: map['note']?.toString() ?? '',
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
    );
  }

  static DateTime dateFrom(dynamic raw) {
    if (raw is Timestamp) {
      return raw.toDate();
    }
    if (raw is DateTime) {
      return raw;
    }
    return DateTime.tryParse(raw?.toString() ?? '') ?? DateTime.now();
  }
}

/// Pure transition rules used by UI + unit tests.
abstract final class OrderTransitions {
  static bool canStaffAdvance(OrderStatus current) {
    return current.nextStaffStatus != null;
  }

  static bool canStaffCancel(OrderStatus current) {
    return !current.isTerminal;
  }

  static bool isValidTransition({
    required OrderStatus from,
    required OrderStatus to,
    required bool isStaff,
  }) {
    if (from == to) return false;
    if (from.isTerminal) return false;

    if (isStaff) {
      if (to == OrderStatus.cancelled) return canStaffCancel(from);
      return from.nextStaffStatus == to;
    }

    // Customer
    if (to == OrderStatus.cancelled) {
      return from == OrderStatus.placed || from == OrderStatus.confirmed;
    }
    if (to == OrderStatus.delivered) {
      return from == OrderStatus.shipping; // confirm received
    }
    return false;
  }
}
