import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/product_model.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/product_image.dart';
import '../../state/auth_controller.dart';
import '../../state/cart_controller.dart';
import '../../state/product_controller.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({required this.productId, super.key});
  final String productId;

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductController>(builder: (context, ctrl, _) {
      final product = ctrl.findById(productId);
      if (product == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Chi tiết sản phẩm')),
          body: EmptyState(
            icon: Icons.search_off,
            title: 'Không tìm thấy sản phẩm',
            message: 'Sản phẩm có thể đã bị xóa khỏi hệ thống.',
            action: FilledButton.icon(
              onPressed: () => context.go(AppRoutes.products),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Quay lại cửa hàng'),
            ),
          ),
        );
      }
      return _SliverContent(product: product);
    });
  }
}

class _SliverContent extends StatelessWidget {
  const _SliverContent({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      bottomNavigationBar: Consumer<AuthController>(builder: (context, auth, _) {
        final user = auth.currentUser;
        if (user == null) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: .2))),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .03),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: user.canShop
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: .05),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ĐƠN GIÁ',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey),
                            ),
                            Text(
                              formatCurrency(product.price),
                              style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            context.read<CartController>().addProduct(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã thêm ${product.name} vào giỏ.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          label: const Text('Thêm vào giỏ hàng'),
                        ),
                      ),
                    ],
                  )
                : FilledButton.icon(
                    onPressed: () => context.go(AppRoutes.editProductDetails(product.id)),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Cập nhật sản phẩm'),
                  ),
          ),
        );
      }),
      body: CustomScrollView(
        slivers: [
          // ── Parallax Image Sliver AppBar ──
          SliverAppBar(
            expandedHeight: 380,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: .9),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
                  onPressed: () => context.go(AppRoutes.products),
                ),
              ),
            ),
            actions: [
              Consumer<AuthController>(builder: (context, auth, _) {
                final user = auth.currentUser;
                if (user == null || !user.canManageProducts) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Row(children: [
                    CircleAvatar(
                      backgroundColor: Colors.white.withValues(alpha: .9),
                      child: IconButton(
                        tooltip: 'Sửa',
                        icon: Icon(Icons.edit_outlined, color: cs.primary, size: 20),
                        onPressed: () => context.go(AppRoutes.editProductDetails(product.id)),
                      ),
                    ),
                    if (user.canDeleteProducts) ...[
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha: .9),
                        child: IconButton(
                          tooltip: 'Xóa',
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () => _confirmDelete(context, product),
                        ),
                      ),
                    ],
                  ]),
                );
              }),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'image-${product.id}',
                child: ProductImage(
                  imageUrl: product.imageUrl,
                  borderRadius: 0,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ),

          // ── Product Details Section ──
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Tag Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: cs.secondary.withValues(alpha: .15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'PHỔ BIẾN',
                            style: TextStyle(
                              color: cs.secondary,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'CÓ SẴN HÀNG',
                            style: TextStyle(
                              color: Color(0xFF16A34A),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      product.name,
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Rating Summary Mock
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '4.8',
                          style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '·  142 đánh giá tích cực',
                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Price Container
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: .06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cs.primary.withValues(alpha: .1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Giá bán trực tuyến:',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            formatCurrency(product.price),
                            style: tt.headlineSmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Description Section
                    Text(
                      'Thông tin sản phẩm',
                      style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description,
                      style: tt.bodyLarge?.copyWith(
                        height: 1.65,
                        color: cs.onSurfaceVariant,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Specification Sheet Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cs.outlineVariant.withValues(alpha: .45)),
                      ),
                      child: Column(
                        children: [
                          _SpecRow(
                            icon: Icons.update_outlined,
                            label: 'Cập nhật cuối',
                            value: formatShortDate(product.updatedAt),
                          ),
                          const Divider(height: 24),
                          _SpecRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Ngày đăng tải',
                            value: formatShortDate(product.createdAt),
                          ),
                          const Divider(height: 24),
                          const _SpecRow(
                            icon: Icons.local_shipping_outlined,
                            label: 'Vận chuyển',
                            value: 'Miễn phí toàn quốc',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.grey, fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w900, color: cs.onSurface, fontSize: 13),
        ),
      ],
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
    context.go(AppRoutes.products);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã xóa ${product.name}.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
