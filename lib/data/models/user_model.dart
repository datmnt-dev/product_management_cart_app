import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_role.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.passwordHash,
    required this.role,
    required this.createdAt,
    this.phone = '',
    this.shopName = '',
    this.bio = '',
  });

  final String id;
  final String fullName;
  final String email;
  final String passwordHash;
  final AppRole role;
  final DateTime createdAt;
  final String phone;
  final String shopName;
  final String bio;

  bool get canManageProducts => role.canManageProducts;
  bool get canDeleteProducts => role.canDeleteProducts;
  bool get canShop => role.canShop;
  bool get canViewRevenue => role.canViewRevenue;
  bool get canManageOrders => role.canManageOrders;
  bool get isStaff => role.isStaff;
  bool get canViewRoleMatrix => role.canViewRoleMatrix;
  bool get isSeller => role == AppRole.seller;
  String get displayShopName =>
      shopName.trim().isEmpty ? fullName : shopName.trim();

  AppUser copyWith({
    String? fullName,
    String? phone,
    String? shopName,
    String? bio,
    AppRole? role,
  }) => AppUser(
    id: id,
    fullName: fullName ?? this.fullName,
    email: email,
    passwordHash: passwordHash,
    role: role ?? this.role,
    createdAt: createdAt,
    phone: phone ?? this.phone,
    shopName: shopName ?? this.shopName,
    bio: bio ?? this.bio,
  );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'passwordHash': passwordHash,
      'role': role.key,
      'createdAt': createdAt.toIso8601String(),
      'phone': phone,
      'shopName': shopName,
      'bio': bio,
    };
  }

  factory AppUser.fromMap(Map<dynamic, dynamic> map) {
    return AppUser(
      id: map['id']?.toString() ?? '',
      fullName: map['fullName']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      passwordHash: map['passwordHash']?.toString() ?? '',
      role: AppRoleX.fromKey(map['role']?.toString()),
      createdAt: _dateFrom(map['createdAt']),
      phone: map['phone']?.toString() ?? '',
      shopName: map['shopName']?.toString() ?? '',
      bio: map['bio']?.toString() ?? '',
    );
  }

  static DateTime _dateFrom(dynamic raw) {
    if (raw is Timestamp) {
      return raw.toDate();
    }
    if (raw is DateTime) {
      return raw;
    }
    return DateTime.tryParse(raw?.toString() ?? '') ?? DateTime.now();
  }
}
