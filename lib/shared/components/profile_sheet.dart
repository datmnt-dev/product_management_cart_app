import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../data/models/user_role.dart';
import '../../state/auth_controller.dart';

/// Account bottom sheet: identity + logout.
class ProfileSheet extends StatelessWidget {
  const ProfileSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const ProfileSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (user == null) {
      return const SizedBox(height: 120, child: Center(child: Text('...')));
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: user.role.accentColor.withValues(alpha: .15),
                child: Icon(
                  user.role.icon,
                  color: user.role.accentColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      user.email,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.role.vietnameseLabel,
                      style: tt.labelSmall?.copyWith(
                        color: user.role.accentColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Chỉnh sửa hồ sơ',
                onPressed: () => _editProfile(context),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.tonalIcon(
            onPressed: () async {
              Navigator.of(context).pop();
              await context.read<AuthController>().logout();
            },
            icon: Icon(Icons.logout, color: cs.error),
            label: Text(
              'Đăng xuất',
              style: TextStyle(color: cs.error, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile(BuildContext context) async {
    final user = context.read<AuthController>().currentUser!;
    final name = TextEditingController(text: user.fullName);
    final phone = TextEditingController(text: user.phone);
    final shop = TextEditingController(text: user.shopName);
    final bio = TextEditingController(text: user.bio);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hồ sơ cá nhân'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Họ và tên'),
              ),
              TextField(
                controller: phone,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
              ),
              if (user.isSeller)
                TextField(
                  controller: shop,
                  decoration: const InputDecoration(labelText: 'Tên shop'),
                ),
              TextField(
                controller: bio,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: user.isSeller ? 'Giới thiệu shop' : 'Giới thiệu',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              await dialogContext.read<AuthController>().updateProfile(
                fullName: name.text,
                phone: phone.text,
                shopName: shop.text,
                bio: bio.text,
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    name.dispose();
    phone.dispose();
    shop.dispose();
    bio.dispose();
  }
}
