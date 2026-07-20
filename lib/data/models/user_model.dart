import 'user_role.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.passwordHash,
    required this.role,
    required this.createdAt,
  });

  final String id;
  final String fullName;
  final String email;
  final String passwordHash;
  final AppRole role;
  final DateTime createdAt;

  bool get canManageProducts => role.canManageProducts;
  bool get canDeleteProducts => role.canDeleteProducts;
  bool get canShop => role.canShop;
  bool get canViewRevenue => role.canViewRevenue;
  bool get canViewRoleMatrix => role.canViewRoleMatrix;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'passwordHash': passwordHash,
      'role': role.key,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<dynamic, dynamic> map) {
    return AppUser(
      id: map['id']?.toString() ?? '',
      fullName: map['fullName']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      passwordHash: map['passwordHash']?.toString() ?? '',
      role: AppRoleX.fromKey(map['role']?.toString()),
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
