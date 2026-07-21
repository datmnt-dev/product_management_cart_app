import 'package:cloud_firestore/cloud_firestore.dart';

enum CouponType { percent, fixedAmount }

extension CouponTypeX on CouponType {
  String get key {
    switch (this) {
      case CouponType.percent:
        return 'percent';
      case CouponType.fixedAmount:
        return 'fixed_amount';
    }
  }

  String get label {
    switch (this) {
      case CouponType.percent:
        return 'Giảm theo %';
      case CouponType.fixedAmount:
        return 'Giảm số tiền';
    }
  }

  static CouponType fromKey(String? key) {
    switch (key) {
      case 'fixed_amount':
      case 'fixed':
        return CouponType.fixedAmount;
      case 'percent':
      default:
        return CouponType.percent;
    }
  }
}

class Coupon {
  const Coupon({
    required this.code,
    required this.type,
    required this.value,
    required this.minOrderAmount,
    required this.maxDiscountAmount,
    required this.startsAt,
    required this.expiresAt,
    this.isActive = true,
    this.usageLimit = 0,
    this.usedCount = 0,
    this.description = '',
  });

  final String code;
  final CouponType type;
  final double value;
  final double minOrderAmount;
  final double maxDiscountAmount;
  final DateTime startsAt;
  final DateTime expiresAt;
  final bool isActive;
  final int usageLimit;
  final int usedCount;
  final String description;

  bool get hasUsageLeft => usageLimit <= 0 || usedCount < usageLimit;

  Coupon copyWith({bool? isActive}) => Coupon(
    code: code,
    type: type,
    value: value,
    minOrderAmount: minOrderAmount,
    maxDiscountAmount: maxDiscountAmount,
    startsAt: startsAt,
    expiresAt: expiresAt,
    isActive: isActive ?? this.isActive,
    usageLimit: usageLimit,
    usedCount: usedCount,
    description: description,
  );

  bool isAvailable(DateTime now) {
    return isActive &&
        hasUsageLeft &&
        !now.isBefore(startsAt) &&
        !now.isAfter(expiresAt);
  }

  double discountFor(double subtotal) {
    if (subtotal < minOrderAmount) return 0;
    final raw = switch (type) {
      CouponType.percent => subtotal * value / 100,
      CouponType.fixedAmount => value,
    };
    final capped = maxDiscountAmount > 0
        ? raw.clamp(0, maxDiscountAmount)
        : raw;
    return capped.clamp(0, subtotal).toDouble();
  }

  Map<String, dynamic> toMap() {
    return {
      'code': normalizeCode(code),
      'type': type.key,
      'value': value,
      'minOrderAmount': minOrderAmount,
      'maxDiscountAmount': maxDiscountAmount,
      'startsAt': startsAt,
      'expiresAt': expiresAt,
      'isActive': isActive,
      'usageLimit': usageLimit,
      'usedCount': usedCount,
      'description': description,
    };
  }

  factory Coupon.fromMap(Map<dynamic, dynamic> map) {
    return Coupon(
      code: normalizeCode(map['code']?.toString() ?? ''),
      type: CouponTypeX.fromKey(map['type']?.toString()),
      value:
          (map['value'] as num?)?.toDouble() ??
          double.tryParse(map['value']?.toString() ?? '') ??
          0,
      minOrderAmount:
          (map['minOrderAmount'] as num?)?.toDouble() ??
          double.tryParse(map['minOrderAmount']?.toString() ?? '') ??
          0,
      maxDiscountAmount:
          (map['maxDiscountAmount'] as num?)?.toDouble() ??
          double.tryParse(map['maxDiscountAmount']?.toString() ?? '') ??
          0,
      startsAt: _dateFrom(map['startsAt']),
      expiresAt: _dateFrom(map['expiresAt']),
      isActive: map['isActive'] != false,
      usageLimit:
          (map['usageLimit'] as num?)?.toInt() ??
          int.tryParse(map['usageLimit']?.toString() ?? '') ??
          0,
      usedCount:
          (map['usedCount'] as num?)?.toInt() ??
          int.tryParse(map['usedCount']?.toString() ?? '') ??
          0,
      description: map['description']?.toString() ?? '',
    );
  }

  static String normalizeCode(String value) {
    return value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
  }

  static DateTime _dateFrom(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw?.toString() ?? '') ?? DateTime.now();
  }
}

class AppliedCoupon {
  const AppliedCoupon({
    required this.code,
    required this.description,
    required this.discountAmount,
  });

  final String code;
  final String description;
  final double discountAmount;
}
