import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/product_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/user_role.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/product_image.dart';
import '../../state/auth_controller.dart';
import '../../state/cart_controller.dart';
import '../../state/product_controller.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _selectedCategory = 'Tất cả';

  final List<String> _categories = [
    'Tất cả',
    'Điện thoại',
    'Laptop',
    'Phụ kiện',
    'Gia dụng',
  ];

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
              child: Icon(Icons.shopping_bag_outlined, color: cs.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text(canManage ? 'Console Kho' : 'StoreFlow Mall'),
          ],
        ),
        actions: [
          if (user?.canViewRoleMatrix ?? false)
            IconButton(
              tooltip: 'Ma trận quyền',
              onPressed: () => context.go(AppRoutes.roles),
              icon: const Icon(Icons.shield_outlined),
            ),
          if (user?.canViewRevenue ?? false)
            IconButton(
              tooltip: 'Doanh thu',
              onPressed: () => context.go(AppRoutes.statistics),
              icon: const Icon(Icons.analytics_outlined),
            ),
          if (user?.canShop ?? false)
            IconButton(
              tooltip: 'Đơn hàng',
              onPressed: () => context.go(AppRoutes.orders),
              icon: const Icon(Icons.local_shipping_outlined),
            ),
          if (user?.canShop ?? false) const _CartBadge(),
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
          _buildCategorySlider(),
          Expanded(
            child: _ProductGrid(
              canManage: canManage,
              user: user,
              selectedCategory: _selectedCategory,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySlider() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = cat);
                }
              },
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
                  child: Icon(u?.role.icon, color: u?.role.accentColor, size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u?.fullName ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black87),
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
              title: Text('Đăng xuất', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
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
          Row(children: [
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
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.3,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
          ]),
        ],
      ),
    );
  }
}

class _SearchTools extends StatelessWidget {
  const _SearchTools();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductController>(builder: (context, ctrl, _) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Column(children: [
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
        ]),
      );
    });
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({
    required this.canManage,
    required this.user,
    required this.selectedCategory,
  });

  final bool canManage;
  final AppUser? user;
  final String selectedCategory;

  List<Product> _filterByCategory(List<Product> list) {
    if (selectedCategory == 'Tất cả') return list;

    final query = selectedCategory.toLowerCase();
    return list.where((p) {
      final name = p.name.toLowerCase();
      final desc = p.description.toLowerCase();

      if (query == 'điện thoại') {
        return name.contains('phone') || name.contains('điện thoại') || desc.contains('phone') || desc.contains('đt');
      } else if (query == 'laptop') {
        return name.contains('laptop') || name.contains('máy tính') || name.contains('macbook') || desc.contains('laptop') || desc.contains('pc');
      } else if (query == 'phụ kiện') {
        return name.contains('tai nghe') || name.contains('cáp') || name.contains('sạc') || name.contains('phụ kiện') || name.contains('ốp') || name.contains('headphone') || desc.contains('nghe') || desc.contains('kết nối');
      } else if (query == 'gia dụng') {
        return name.contains('nồi') || name.contains('bếp') || name.contains('quạt') || name.contains('gia dụng') || desc.contains('nấu') || desc.contains('nhà bếp');
      }
      return name.contains(query) || desc.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductController>(builder: (context, ctrl, _) {
      final filteredList = _filterByCategory(ctrl.visibleProducts);

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
    });
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
            onTap: () => context.go(AppRoutes.productDetails(widget.product.id)),
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                                if (a == 'edit') context.go(AppRoutes.editProductDetails(widget.product.id));
                                if (a == 'delete') _confirmDelete(context, widget.product);
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(Icons.edit_outlined),
                                    title: Text('Cập nhật', style: TextStyle(fontWeight: FontWeight.w700)),
                                  ),
                                ),
                                if (widget.canDelete)
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(Icons.delete_outline, color: Colors.red),
                                      title: Text(
                                        'Xóa',
                                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
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
                        style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w900, fontSize: 13),
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
                                context.read<CartController>().addProduct(widget.product);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Đã thêm ${widget.product.name} vào giỏ.'),
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

class _CartBadge extends StatelessWidget {
  const _CartBadge();

  @override
  Widget build(BuildContext context) {
    return Consumer<CartController>(builder: (context, cart, _) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            tooltip: 'Giỏ hàng',
            onPressed: () => context.go(AppRoutes.cart),
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
          if (cart.totalQuantity > 0)
            Positioned(
              right: 2,
              top: 2,
              child: TweenAnimationBuilder<double>(
                key: ValueKey(cart.totalQuantity),
                tween: Tween(begin: 0.6, end: 1.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                builder: (context, val, child) {
                  return Transform.scale(
                    scale: val,
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.secondary.withValues(alpha: .35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    cart.totalQuantity > 99 ? '99+' : '${cart.totalQuantity}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
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
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
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
