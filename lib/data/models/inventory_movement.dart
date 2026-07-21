import 'package:cloud_firestore/cloud_firestore.dart';

enum InventoryMovementType { restock, adjustment }

extension InventoryMovementTypeX on InventoryMovementType {
  String get key =>
      this == InventoryMovementType.restock ? 'restock' : 'adjustment';
  String get label =>
      this == InventoryMovementType.restock ? 'Nhập hàng' : 'Điều chỉnh';
  static InventoryMovementType fromKey(String? value) => value == 'restock'
      ? InventoryMovementType.restock
      : InventoryMovementType.adjustment;
}

class InventoryMovement {
  const InventoryMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantityDelta,
    required this.stockBefore,
    required this.stockAfter,
    required this.note,
    required this.byEmail,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String productName;
  final InventoryMovementType type;
  final int quantityDelta;
  final int stockBefore;
  final int stockAfter;
  final String note;
  final String byEmail;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'productId': productId,
    'productName': productName,
    'type': type.key,
    'quantityDelta': quantityDelta,
    'stockBefore': stockBefore,
    'stockAfter': stockAfter,
    'note': note,
    'byEmail': byEmail,
    'createdAt': createdAt,
  };

  factory InventoryMovement.fromMap(Map<String, dynamic> map) {
    final raw = map['createdAt'];
    return InventoryMovement(
      id: map['id']?.toString() ?? '',
      productId: map['productId']?.toString() ?? '',
      productName: map['productName']?.toString() ?? '',
      type: InventoryMovementTypeX.fromKey(map['type']?.toString()),
      quantityDelta: (map['quantityDelta'] as num?)?.toInt() ?? 0,
      stockBefore: (map['stockBefore'] as num?)?.toInt() ?? 0,
      stockAfter: (map['stockAfter'] as num?)?.toInt() ?? 0,
      note: map['note']?.toString() ?? '',
      byEmail: map['byEmail']?.toString() ?? '',
      createdAt: raw is Timestamp
          ? raw.toDate()
          : raw is DateTime
          ? raw
          : DateTime.tryParse(raw?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
