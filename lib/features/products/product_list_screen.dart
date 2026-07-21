import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/load_status.dart';
import '../../data/models/user_model.dart';
import '../../data/models/user_role.dart';
import '../../shared/components/category_chip_bar.dart';
import '../../shared/components/product_card.dart';
import '../../shared/components/profile_sheet.dart';
import '../../shared/widgets/app_error_state.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/skeleton.dart';
import '../../state/auth_controller.dart';
import '../../state/product_controller.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final canManage = user?.canManageProducts ?? false;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: .1),
                borderRadius: AppRadii.borderMd,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                color: cs.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(canManage ? 'Console Kho' : 'StoreFlow Mall'),
          ],
        ),
        actions: const [
          _AccountMenu(),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => context.go(AppRoutes.newProduct),
              icon: const Icon(Icons.add),
              label: const Text('Thêm sản phẩm'),
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
            )
          : null,
      body: Column(
        children: [
          if (user != null) _CompactRoleStrip(user: user),
          const _SearchTools(),
          const CategoryChipBar(),
          if (canManage) ...[
            const SizedBox(height: AppSpacing.xs),
            const StatusFilterChipBar(),
            const SizedBox(height: AppSpacing.xs),
          ] else
            const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: _ProductGrid(canManage: canManage, user: user),
          ),
        ],
      ),
    );
  }
}

class _AccountMenu extends StatelessWidget {
  const _AccountMenu();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    return IconButton(
      tooltip: 'Tài khoản',
      onPressed: () => ProfileSheet.show(context),
      icon: CircleAvatar(
        radius: 16,
        backgroundColor:
            (user?.role.accentColor ?? Theme.of(context).colorScheme.primary)
                .withValues(alpha: .15),
        child: Icon(
          user?.role.icon ?? Icons.account_circle_outlined,
          size: 18,
          color: user?.role.accentColor ??
              Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// Compact greeting strip (replaces large role header).
class _CompactRoleStrip extends StatelessWidget {
  const _CompactRoleStrip({required this.user});

  final AppUser user;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final role = user.role;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: role.accentColor.withValues(alpha: .15),
            child: Text(
              _initials(user.fullName),
              style: TextStyle(
                color: role.accentColor,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào, ${user.fullName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  role.vietnameseLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: role.accentColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Icon(role.icon, color: cs.onSurfaceVariant, size: 18),
        ],
      ),
    );
  }
}

class _SearchTools extends StatelessWidget {
  const _SearchTools();

  @override
  Widget build(BuildContext context) {
    final canManage =
        context.watch<AuthController>().currentUser?.canManageProducts ?? false;

    return Consumer<ProductController>(
      builder: (context, ctrl, _) {
        return Material(
          elevation: 0,
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xxs,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Column(
              children: [
                TextField(
                  onChanged: ctrl.setSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Tìm tên, mô tả, SKU...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: ctrl.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () => ctrl.setSearchQuery(''),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        SegmentedButton<ProductSort>(
                          selected: {ctrl.sort},
                          onSelectionChanged: (s) => ctrl.setSort(s.first),
                          segments: [
                            const ButtonSegment(
                              value: ProductSort.newest,
                              icon: Icon(Icons.watch_later_outlined, size: 15),
                              label: Text('Mới'),
                            ),
                            const ButtonSegment(
                              value: ProductSort.priceAsc,
                              icon: Icon(Icons.trending_up, size: 15),
                              label: Text('Giá ↑'),
                            ),
                            const ButtonSegment(
                              value: ProductSort.priceDesc,
                              icon: Icon(Icons.trending_down, size: 15),
                              label: Text('Giá ↓'),
                            ),
                            if (canManage)
                              const ButtonSegment(
                                value: ProductSort.stockDesc,
                                icon: Icon(Icons.inventory_2_outlined, size: 15),
                                label: Text('Tồn'),
                              ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Còn hàng'),
                          selected: ctrl.inStockOnly,
                          onSelected: ctrl.setInStockOnly,
                          avatar: Icon(
                            Icons.check_circle_outline,
                            size: 16,
                            color: ctrl.inStockOnly
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                        ),
                        if (ctrl.hasActiveFilters) ...[
                          const SizedBox(width: 8),
                          ActionChip(
                            label: const Text('Xóa bộ lọc'),
                            avatar: const Icon(Icons.filter_alt_off, size: 16),
                            onPressed: ctrl.clearFilters,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.canManage, required this.user});

  final bool canManage;
  final AppUser? user;

  static int columnsForWidth(double width) {
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = columnsForWidth(width);

    return Consumer<ProductController>(
      builder: (context, ctrl, _) {
        if (ctrl.status == LoadStatus.loading && ctrl.products.isEmpty) {
          return ProductGridSkeleton(crossAxisCount: crossAxisCount);
        }

        if (ctrl.hasError && ctrl.products.isEmpty) {
          return AppErrorState(
            title: 'Không tải được sản phẩm',
            message:
                ctrl.errorMessage ??
                'Không thể tải sản phẩm. Kiểm tra kết nối mạng và thử lại.',
            onRetry: ctrl.retry,
          );
        }

        final filteredList = ctrl.visibleProducts;

        if (filteredList.isEmpty) {
          return EmptyState(
            icon: Icons.grid_view_rounded,
            title: 'Sản phẩm trống',
            message: ctrl.searchQuery.isEmpty
                ? 'Không có sản phẩm nào thuộc danh mục này.'
                : 'Không có sản phẩm nào khớp với từ khóa tìm kiếm.',
            action: canManage
                ? FilledButton.icon(
                    onPressed: () => context.go(AppRoutes.newProduct),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm sản phẩm'),
                  )
                : null,
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xxs,
            AppSpacing.md,
            AppSpacing.xxxl + AppSpacing.md,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.65,
          ),
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final product = filteredList[index];
            return _AnimatedEntrance(
              index: index,
              child: ProductCard(
                product: product,
                canManage: user?.canManageProducts ?? false,
                canDelete: user?.canDeleteProducts ?? false,
                canShop: user?.canShop ?? false,
              ),
            );
          },
        );
      },
    );
  }
}

class _AnimatedEntrance extends StatelessWidget {
  const _AnimatedEntrance({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduceMotion(context)) {
      return child;
    }

    final delay = AppMotion.staggerDelay(index);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: AppMotion.enter + delay,
      curve: AppMotion.staggerCurve,
      builder: (context, val, child) {
        return Opacity(
          opacity: val.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - val)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
