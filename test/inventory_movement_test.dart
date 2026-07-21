import 'package:flutter_test/flutter_test.dart';
import 'package:product_management_cart_app/data/models/inventory_movement.dart';

void main() {
  test('inventory movement preserves signed stock delta', () {
    final movement = InventoryMovement(
      id: 'm1',
      productId: 'p1',
      productName: 'Demo',
      type: InventoryMovementType.adjustment,
      quantityDelta: -2,
      stockBefore: 5,
      stockAfter: 3,
      note: 'Hàng lỗi',
      byEmail: 'manager@store.local',
      createdAt: DateTime(2026),
    );
    final restored = InventoryMovement.fromMap(movement.toMap());
    expect(restored.quantityDelta, -2);
    expect(restored.stockAfter, 3);
  });
}
