import 'package:flutter_test/flutter_test.dart';
import 'package:product_management_cart_app/data/models/order_model.dart';

void main() {
  group('OrderTransitions', () {
    test('staff advances along the happy path', () {
      expect(
        OrderTransitions.isValidTransition(
          from: OrderStatus.placed,
          to: OrderStatus.confirmed,
          isStaff: true,
        ),
        isTrue,
      );
      expect(
        OrderTransitions.isValidTransition(
          from: OrderStatus.confirmed,
          to: OrderStatus.preparing,
          isStaff: true,
        ),
        isTrue,
      );
      expect(
        OrderTransitions.isValidTransition(
          from: OrderStatus.preparing,
          to: OrderStatus.shipping,
          isStaff: true,
        ),
        isTrue,
      );
      expect(
        OrderTransitions.isValidTransition(
          from: OrderStatus.shipping,
          to: OrderStatus.delivered,
          isStaff: true,
        ),
        isTrue,
      );
    });

    test('staff cannot skip steps', () {
      expect(
        OrderTransitions.isValidTransition(
          from: OrderStatus.placed,
          to: OrderStatus.shipping,
          isStaff: true,
        ),
        isFalse,
      );
    });

    test('customer can cancel early and confirm received when shipping', () {
      expect(
        OrderTransitions.isValidTransition(
          from: OrderStatus.placed,
          to: OrderStatus.cancelled,
          isStaff: false,
        ),
        isTrue,
      );
      expect(
        OrderTransitions.isValidTransition(
          from: OrderStatus.shipping,
          to: OrderStatus.delivered,
          isStaff: false,
        ),
        isTrue,
      );
      expect(
        OrderTransitions.isValidTransition(
          from: OrderStatus.placed,
          to: OrderStatus.confirmed,
          isStaff: false,
        ),
        isFalse,
      );
    });

    test('terminal states block further transitions', () {
      expect(
        OrderTransitions.isValidTransition(
          from: OrderStatus.delivered,
          to: OrderStatus.cancelled,
          isStaff: true,
        ),
        isFalse,
      );
      expect(
        OrderTransitions.isValidTransition(
          from: OrderStatus.cancelled,
          to: OrderStatus.placed,
          isStaff: true,
        ),
        isFalse,
      );
    });

    test('withStatusTransition appends history', () {
      final now = DateTime(2026, 7, 20, 10);
      final order = OrderModel(
        id: 'o1',
        userEmail: 'customer@store.local',
        items: const [],
        totalAmount: 100,
        createdAt: now,
        status: OrderStatus.placed,
        statusHistory: [
          OrderStatusEvent(
            status: OrderStatus.placed,
            at: now,
            byEmail: 'customer@store.local',
            note: 'sent',
          ),
        ],
      );

      final next = order.withStatusTransition(
        next: OrderStatus.confirmed,
        byEmail: 'admin@store.local',
        note: 'shop received',
        at: now.add(const Duration(hours: 1)),
      );

      expect(next.status, OrderStatus.confirmed);
      expect(next.statusHistory.length, 2);
      expect(next.statusHistory.last.byEmail, 'admin@store.local');
      expect(next.status.countsTowardRevenue, isTrue);
      expect(OrderStatus.cancelled.countsTowardRevenue, isFalse);
    });
  });
}
