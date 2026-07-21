import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/order_model.dart';
import 'auth_controller.dart';
import 'order_controller.dart';

class OrderAlert {
  const OrderAlert({
    required this.orderId,
    required this.status,
    required this.message,
    required this.at,
  });

  final String orderId;
  final OrderStatus status;
  final String message;
  final DateTime at;

  String get shortId => orderId.split('-').last.toUpperCase();
}

/// In-app order status change alerts (no FCM). Customer-focused.
class OrderAlertController extends ChangeNotifier {
  OrderAlertController({
    required AuthController authController,
    required OrderController orderController,
    required SharedPreferences preferences,
  }) : _auth = authController,
       _orders = orderController,
       _prefs = preferences {
    _auth.addListener(_onAuthChanged);
    _orders.addListener(_onOrdersChanged);
    // Never notifyListeners() synchronously in the constructor — Provider
    // create is still running and reassemble/hot-reload will crash.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      _onAuthChanged();
    });
  }

  final AuthController _auth;
  final OrderController _orders;
  final SharedPreferences _prefs;

  final List<OrderAlert> _alerts = [];
  Map<String, String> _lastSeen = {};
  bool _bootstrapped = false;
  int _unread = 0;
  bool _disposed = false;

  List<OrderAlert> get alerts => List.unmodifiable(_alerts);
  int get unreadCount => _unread;
  bool get hasUnread => _unread > 0;

  OrderAlert? get latest => _alerts.isEmpty ? null : _alerts.first;

  void markAllRead() {
    if (_disposed) return;
    _unread = 0;
    notifyListeners();
  }

  void dismissLatest() {
    if (_disposed || _alerts.isEmpty) return;
    _alerts.removeAt(0);
    if (_unread > 0) _unread--;
    notifyListeners();
  }

  void _onAuthChanged() {
    if (_disposed) return;
    final email = _auth.currentUser?.email.trim().toLowerCase();
    _bootstrapped = false;
    _alerts.clear();
    _unread = 0;
    _lastSeen = {};
    if (email != null && email.isNotEmpty) {
      _loadSeen(email);
    }
    notifyListeners();
  }

  void _onOrdersChanged() {
    if (_disposed) return;
    final user = _auth.currentUser;
    if (user == null || !user.canShop) return;
    if (_orders.orders.isEmpty && !_bootstrapped) return;

    final email = user.email.trim().toLowerCase();
    final mine = _orders.ordersForEmail(email);

    if (!_bootstrapped) {
      for (final o in mine) {
        _lastSeen[o.id] = o.status.key;
      }
      _bootstrapped = true;
      _saveSeen(email);
      return;
    }

    var changed = false;
    for (final o in mine) {
      final prev = _lastSeen[o.id];
      if (prev == null) {
        _lastSeen[o.id] = o.status.key;
        _pushAlert(
          OrderAlert(
            orderId: o.id,
            status: o.status,
            message: 'Đơn đã được tạo — ${o.status.label}',
            at: o.lastUpdated,
          ),
        );
        changed = true;
        continue;
      }
      if (prev != o.status.key) {
        _lastSeen[o.id] = o.status.key;
        _pushAlert(
          OrderAlert(
            orderId: o.id,
            status: o.status,
            message: 'Đơn #${o.id.split('-').last} → ${o.status.label}',
            at: o.lastUpdated,
          ),
        );
        changed = true;
      }
    }

    if (changed) {
      _saveSeen(email);
      notifyListeners();
    }
  }

  void _pushAlert(OrderAlert alert) {
    _alerts.insert(0, alert);
    if (_alerts.length > 20) {
      _alerts.removeRange(20, _alerts.length);
    }
    _unread++;
  }

  String _seenKey(String email) => 'order_seen_v1_$email';

  void _loadSeen(String email) {
    final raw = _prefs.getString(_seenKey(email));
    if (raw == null || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw);
      if (map is Map) {
        _lastSeen = {
          for (final e in map.entries) e.key.toString(): e.value.toString(),
        };
      }
    } catch (_) {}
  }

  void _saveSeen(String email) {
    try {
      _prefs.setString(_seenKey(email), jsonEncode(_lastSeen));
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
    _auth.removeListener(_onAuthChanged);
    _orders.removeListener(_onOrdersChanged);
    super.dispose();
  }
}
