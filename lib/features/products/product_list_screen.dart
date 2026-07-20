import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/load_status.dart';
import '../../data/models/product_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/user_role.dart';
import '../../shared/widgets/app_error_state.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/product_image.dart';
import '../../shared/widgets/skeleton.dart';
import '../../state/auth_controller.dart';
import '../../state/cart_controller.dart';
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
                borderRadius: BorderRadius.circular(10),
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
        // Cross-links (roles/stats/orders/cart) live in AppShell tabs.
        actions: [
          _AccountMenu(),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => context.go(AppRoutes.newProduct),
              icon: const Icon(Icons.add),
              label: const Text('Thêm sản phẩm'),
              backgroundColor: cs.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: Column(
        children: [
          if (user != null) _RoleHeader(user: user),
          const _SearchTools(),
          const _CategorySlider(),
          Expanded(
            child: _ProductGrid(canManage: canManage, user: user),
          ),
        ],
      ),
    );
  }
}

class _CategorySlider extends StatelessWidget {
  const _CategorySlider();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Consumer<ProductController>(
      builder: (context, ctrl, _) {
        final categories = <ProductCategory?>[null, ...ProductCategory.values];
        return Container(
          height: 48,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = ctrl.category == category;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(category?.label ?? 'Tất cả'),
                  selected: isSelected,
                  onSelected: (_) => ctrl.setCategory(category),
                  selectedColor: cs.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : cs.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isSelected
                        ? cs.primary
                        : cs.outlineVariant.withValues(alpha: .5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  showCheckmark: false,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _AccountMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Tài khoản',
      icon: const Icon(Icons.account_circle_outlined),
      onSelected: (v) {
        if (v == 'logout') context.read<AuthController>().logout();
      },
      itemBuilder: (_) {
        final u = context.read<AuthController>().currentUser;
        return [
          PopupMenuItem(
            enabled: false,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: u?.role.accentColor.withValues(alpha: .15),
                  child: Icon(
                    u?.role.icon,
                    color: u?.role.accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u?.fullName ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      u?.role.vietnameseLabel ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: u?.role.accentColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'logout',
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text(
                'Đăng xuất',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ];
      },
    );
  }
}

class _RoleHeader extends StatelessWidget {
  const _RoleHeader({required this.user});
  final AppUser user;

  String _initials(String n) {
    final p = n.trim().split(RegExp(r'\s+'));
    if (p.length >= 2) return '${p.first[0]}${p.last[0]}'.toUpperCase();
    return p.first.isNotEmpty ? p.first[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final role = user.role;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            role.accentColor.withValues(alpha: .08),
            role.accentColor.withValues(alpha: .02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: role.accentColor.withValues(alpha: .2)),
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
                  gradient: LinearGradient(
                    colors: [
                      role.accentColor,
                      role.accentColor.withValues(alpha: .75),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: role.accentColor.withValues(alpha: .2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _initials(user.fullName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -.3,
                              ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: role.accentColor.withValues(alpha: .15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            role.vietnameseLabel,
                            style: TextStyle(
                              fontSize: 9,
                              color: role.accentColor,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchTools extends StatelessWidget {
  const _SearchTools();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductController>(
      builder: (context, ctrl, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Column(
            children: [
              TextField(
                onChanged: ctrl.setSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Tìm sản phẩm & thương hiệu...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: ctrl.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => ctrl.setSearchQuery(''),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<ProductSort>(
                    selected: {ctrl.sort},
                    onSelectionChanged: (s) => ctrl.setSort(s.first),
                    segments: const [
                      ButtonSegment(
                        value: ProductSort.newest,
                        icon: Icon(Icons.watch_later_outlined, size: 15),
                        label: Text('Mới nhất'),
                      ),
                      ButtonSegment(
                        value: ProductSort.priceAsc,
                        icon: Icon(Icons.trending_up, size: 15),
                        label: Text('Giá thấp'),
                      ),
                      ButtonSegment(
                        value: ProductSort.priceDesc,
                        icon: Icon(Icons.trending_down, size: 15),
                        label: Text('Giá cao'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductController>(
      builder: (context, ctrl, _) {
        // First load / empty cache
        if (ctrl.status == LoadStatus.loading && ctrl.products.isEmpty) {
          return const ProductGridSkeleton();
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
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.65,
          ),
          itemCount: filteredList.length,
          itemBuilder: (_, i) => _AnimatedEntrance(
            index: i,
            child: _GridTile(
              product: filteredList[i],
              canManage: user?.canManageProducts ?? false,
              canDelete: user?.canDeleteProducts ?? false,
              canShop: user?.canShop ?? false,
            ),
          ),
        );
      },
    );
  }
}

// ── Staggered Entrance Animation Wrapper ──
class _AnimatedEntrance extends StatelessWidget {
  const _AnimatedEntrance({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 60).clamp(0, 400)),
      curve: Curves.easeOutBack,
      builder: (context, val, child) {
        return Opacity(
          opacity: val,
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

class _GridTile extends StatefulWidget {
  const _GridTile({
    required this.product,
    required this.canManage,
    required this.canDelete,
    required this.canShop,
  });

  final Product product;
  final bool canManage, canDelete, canShop;

  @override
  State<_GridTile> createState() => _GridTileState();
}

class _GridTileState extends State<_GridTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: Card(
          elevation: _isHovered ? 4 : 0,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () =>
                context.go(AppRoutes.productDetails(widget.product.id)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Frame
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ProductImage(
                        imageUrl: widget.product.imageUrl,
                        borderRadius: 0,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: cs.secondary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      if (widget.canManage)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .9),
                              shape: BoxShape.circle,
                            ),
                            child: PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.more_vert, size: 18),
                              onSelected: (a) {
                                if (a == 'edit') {
                                  context.go(
                                    AppRoutes.editProductDetails(
                                      widget.product.id,
                                    ),
                                  );
                                }
                                if (a == 'delete') {
                                  _confirmDelete(context, widget.product);
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(Icons.edit_outlined),
                                    title: Text(
                                      'Cập nhật',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                if (widget.canDelete)
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      title: Text(
                                        'Xóa',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Product Details Block
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.product.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.product.category.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            widget.product.isInStock
                                ? 'Kho: ${widget.product.stockQuantity}'
                                : 'Hết hàng',
                            style: TextStyle(
                              color: widget.product.canBePurchased
                                  ? const Color(0xFF16A34A)
                                  : cs.error,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              formatCurrency(widget.product.price),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (widget.canShop)
                            GestureDetector(
                              onTap: () {
                                final added = context
                                    .read<CartController>()
                                    .addProduct(widget.product);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      added
                                          ? 'Đã thêm ${widget.product.name} vào giỏ.'
                                          : '${widget.product.name} hiện không đủ hàng.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: .08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.add_shopping_cart,
                                  size: 14,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _confirmDelete(BuildContext context, Product product) async {
  final cs = Theme.of(context).colorScheme;
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Xóa sản phẩm?'),
      content: Text('Sản phẩm "${product.name}" sẽ bị xóa vĩnh viễn.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: cs.error),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  await context.read<ProductController>().deleteProduct(product.id);
  if (context.mounted) {
    context.read<CartController>().remove(product.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã xóa ${product.name}.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
