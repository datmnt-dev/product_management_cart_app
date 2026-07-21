import 'package:flutter_test/flutter_test.dart';
import 'package:product_management_cart_app/data/models/coupon_model.dart';

void main() {
  group('Coupon', () {
    test('normalizes code and caps percent discount', () {
      final now = DateTime(2026, 7, 21);
      final coupon = Coupon(
        code: ' welcome10 ',
        type: CouponType.percent,
        value: 10,
        minOrderAmount: 100,
        maxDiscountAmount: 50,
        startsAt: now.subtract(const Duration(days: 1)),
        expiresAt: now.add(const Duration(days: 1)),
      );

      expect(Coupon.normalizeCode(' welcome 10 '), 'WELCOME10');
      expect(coupon.isAvailable(now), isTrue);
      expect(coupon.discountFor(1000), 50);
    });

    test('fixed discount respects subtotal and availability', () {
      final now = DateTime(2026, 7, 21);
      final coupon = Coupon(
        code: 'SHIP50',
        type: CouponType.fixedAmount,
        value: 50000,
        minOrderAmount: 300000,
        maxDiscountAmount: 50000,
        startsAt: now.subtract(const Duration(days: 1)),
        expiresAt: now.add(const Duration(days: 1)),
        usageLimit: 1,
        usedCount: 1,
      );

      expect(coupon.isAvailable(now), isFalse);
      expect(coupon.discountFor(200000), 0);
      expect(coupon.discountFor(320000), 50000);
    });
  });
}
