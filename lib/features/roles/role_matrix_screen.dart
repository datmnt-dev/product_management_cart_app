import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../data/models/user_role.dart';
import '../../state/auth_controller.dart';

class RoleMatrixScreen extends StatelessWidget {
  const RoleMatrixScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân quyền truy cập'),
        actions: [
          IconButton(
            tooltip: 'Sản phẩm',
            onPressed: () => context.go(AppRoutes.products),
            icon: const Icon(Icons.storefront_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Premium Console Info Header ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cs.primary, cs.primary.withValues(alpha: .85)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: .18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.security, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Role-Based Security Console',
                        style: tt.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Hệ thống quản lý quyền truy cập phân vai trò (RBAC) đồng bộ chặt chẽ giữa Router điều hướng và hiển thị giao diện của StoreFlow.',
                  style: TextStyle(color: Colors.white.withValues(alpha: .82), height: 1.45, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Tài khoản hiện tại: ${user?.fullName ?? "Khách"} (${user?.role.vietnameseLabel ?? "Chưa đăng nhập"})',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Credentials list ──
          Text('Tài khoản Test nhanh', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          const _AccountCard(role: AppRole.admin, email: 'admin@store.local'),
          const SizedBox(height: 8),
          const _AccountCard(role: AppRole.manager, email: 'manager@store.local'),
          const SizedBox(height: 8),
          const _AccountCard(role: AppRole.customer, email: 'customer@store.local'),
          const SizedBox(height: 24),

          // ── Dynamic Permissions matrix ──
          Text('Bảng đặc quyền chi tiết', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          ...AppRole.values.map((role) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _RolePermissionsCard(role: role),
          )),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.role, required this.email});
  final AppRole role;
  final String email;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: role.accentColor.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(role.icon, color: role.accentColor, size: 18),
        ),
        title: Text(
          role.vietnameseLabel,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        ),
        subtitle: Text(
          '$email · Mật khẩu: 123456',
          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
        ),
        dense: true,
      ),
    );
  }
}

class _RolePermissionsCard extends StatelessWidget {
  const _RolePermissionsCard({required this.role});
  final AppRole role;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: role.accentColor, width: 4.5)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: role.accentColor.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(role.icon, color: role.accentColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.vietnameseLabel,
                        style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        role.description,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _AccessRow(label: 'Xem danh sách & Chi tiết sản phẩm', allowed: true),
            _AccessRow(label: 'Quản lý kho hàng (Thêm & Sửa sản phẩm)', allowed: role.canManageProducts),
            _AccessRow(label: 'Xóa sản phẩm khỏi hệ thống', allowed: role.canDeleteProducts),
            _AccessRow(label: 'Mua sắm & Đặt hàng (Shopping Cart)', allowed: role.canShop),
            _AccessRow(label: 'Xem thống kê doanh thu toàn hệ thống', allowed: role.canViewRevenue),
            _AccessRow(label: 'Truy cập ma trận bảo mật', allowed: role.canViewRoleMatrix),
          ],
        ),
      ),
    );
  }
}

class _AccessRow extends StatelessWidget {
  const _AccessRow({required this.label, required this.allowed});
  final String label;
  final bool allowed;

  @override
  Widget build(BuildContext context) {
    final color = allowed
        ? const Color(0xFF16A34A)
        : Theme.of(context).colorScheme.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              allowed ? Icons.check : Icons.close,
              color: color,
              size: 13,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                color: allowed ? Colors.black87 : Colors.black45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
