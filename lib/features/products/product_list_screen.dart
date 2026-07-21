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
            Flexible(
              child: Text(
                canManage ? 'Console Kho' : 'StoreFlow Mall',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (canManage)
            IconButton(
              tooltip: 'Quản lý mã giảm giá',
              onPressed: () => context.go(AppRoutes.coupons),
              icon: const Icon(Icons.confirmation_num_outlined),
            ),
          const _AccountMenu(),
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
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
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
        ),
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
          color:
              user?.role.accentColor ?? Theme.of(context).colorScheme.primary,
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
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
    final cs = Theme.of(context).colorScheme;

    return Consumer<ProductController>(
      builder: (context, ctrl, _) {
        return Material(
          elevation: 0,
          color: cs.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xxs,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  onChanged: ctrl.setSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Tìm tên, mô tả, SKU...',
                    isDense: true,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: ctrl.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () => ctrl.setSearchQuery(''),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                // Single horizontal strip — avoids SegmentedButton overflow on web.
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final entry in <(ProductSort, String, IconData)>[
                        (ProductSort.newest, 'Mới', Icons.watch_later_outlined),
                        (ProductSort.priceAsc, 'Giá ↑', Icons.trending_up),
                        (ProductSort.priceDesc, 'Giá ↓', Icons.trending_down),
                        if (canManage)
                          (
                            ProductSort.stockDesc,
                            'Tồn',
                            Icons.inventory_2_outlined,
                          ),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(entry.$2),
                            avatar: Icon(entry.$3, size: 16),
                            selected: ctrl.sort == entry.$1,
                            onSelected: (_) => ctrl.setSort(entry.$1),
                            showCheckmark: false,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text('Còn hàng'),
                          selected: ctrl.inStockOnly,
                          onSelected: ctrl.setInStockOnly,
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      if (ctrl.hasActiveFilters)
                        ActionChip(
                          label: const Text('Xóa lọc'),
                          avatar: const Icon(Icons.filter_alt_off, size: 16),
                          onPressed: ctrl.clearFilters,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
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
    // Content is often inset by NavigationRail (~88px) on wide web.
    if (width >= 1100) return 4;
    if (width >= 720) return 3;
    return 2;
  }

  /// Taller cards on narrow columns tend to overflow footer text/actions.
  static double aspectFor(int columns) {
    switch (columns) {
      case 4:
        return 0.72;
      case 3:
        return 0.70;
      default:
        return 0.68;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = columnsForWidth(width);
        final aspect = aspectFor(crossAxisCount);

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
                    : TextButton(
                        onPressed: ctrl.clearFilters,
                        child: const Text('Xóa bộ lọc'),
                      ),
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
                childAspectRatio: aspect,
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
