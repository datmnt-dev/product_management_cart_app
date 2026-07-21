import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_management_cart_app/core/theme/app_theme.dart';
import 'package:product_management_cart_app/data/models/coupon_model.dart';
import 'package:product_management_cart_app/features/cart/cart_screen.dart';

void main() {
  testWidgets('checkout sheet renders without infinite button width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 360,
              child: buildCheckoutSheetForTest(
                totalQuantity: 2,
                totalPrice: 500000,
                defaultName: 'Mai',
                onPreviewCoupon: (_) async {
                  return const AppliedCoupon(
                    code: 'WELCOME10',
                    description: 'Giảm 10%',
                    discountAmount: 50000,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Mã giảm giá'), findsOneWidget);
    expect(find.text('Áp dụng'), findsOneWidget);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -600),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Xác nhận đặt hàng'), findsOneWidget);
  });
}
