import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_management_cart_app/shared/widgets/app_error_state.dart';

void main() {
  testWidgets('AppErrorState retry button invokes callback', (tester) async {
    var retries = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppErrorState(
            title: 'Không tải được',
            message: 'Mất kết nối mạng.',
            onRetry: () => retries++,
          ),
        ),
      ),
    );

    expect(find.text('Không tải được'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);

    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    expect(retries, 1);
  });
}
