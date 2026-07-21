import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/load_status.dart';
import '../../data/models/product_model.dart';
import '../../shared/components/cart_badge_icon.dart';
import '../../shared/components/price_text.dart';
import '../../shared/components/primary_bottom_bar.dart';
import '../../shared/components/status_chip.dart';
import '../../shared/widgets/app_error_state.dart';
import '../../shared/widgets/app_loading_state.dart';
import '../../shared/widgets/confirm_dialog.dart';
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
    return Consumer2<ProductController, AuthController>(
      builder: (context, ctrl, auth, _) {
        final product = ctrl.findById(productId);

        // Wait for first stream snapshot when product not cached yet.
        if (product == null &&
            (ctrl.status == LoadStatus.loading ||
                ctrl.status == LoadStatus.idle)) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chi tiết sản phẩm')),
            body: const AppLoadingState(message: 'Đang tải sản phẩm...'),
          );
        }

        if (product == null && ctrl.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chi tiết sản phẩm')),
            body: AppErrorState(
              title: 'Không tải được sản phẩm',
              message:
                  ctrl.errorMessage ??
                  'Không thể tải sản phẩm. Kiểm tra kết nối mạng và thử lại.',
              onRetry: ctrl.retry,
            ),
          );
        }

        // UX-only storefront guard (Goal #5 / §5.2) — do not regress.
        final unavailable =
            product == null || !ctrl.isVisibleToCurrentUser(product);

        if (unavailable) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chi tiết sản phẩm')),
            body: EmptyState(
              icon: Icons.search_off,
              title: 'Không tìm thấy sản phẩm',
              message:
                  'Sản phẩm không tồn tại hoặc không khả dụng trên cửa hàng.',
              action: FilledButton.icon(
                onPressed: () => context.go(AppRoutes.products),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Quay lại cửa hàng'),
              ),
            ),
          );
        }

        return _DetailContent(product: product);
      },
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      bottomNavigationBar: Consumer2<AuthController, CartController>(
        builder: (context, auth, cart, _) {
          final user = auth.currentUser;
          if (user == null) return const SizedBox.shrink();

          if (user.canShop) {
            final canBuy = product.canBePurchased;
            return PrimaryBottomBar(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Giá bán',
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        PriceText(product.price, fontSize: 20),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: canBuy
                          ? () {
                              HapticFeedback.lightImpact();
                              final added = cart.addProduct(product);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    added
                                        ? 'Đã thêm ${product.name} vào giỏ.'
                                        : '${product.name} hiện không đủ hàng.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  action: added
                                      ? SnackBarAction(
                                          label: 'Xem giỏ',
                                          onPressed: () =>
                                              context.go(AppRoutes.cart),
                                        )
                                      : null,
                                ),
                              );
                            }
                          : null,
                      icon: Icon(
                        canBuy ? Icons.add_shopping_cart_rounded : Icons.block,
                      ),
                      label: Text(canBuy ? 'Thêm vào giỏ' : 'Không thể mua'),
                    ),
                  ),
                ],
              ),
            );
          }

          if (user.canManageProducts) {
            return PrimaryBottomBar(
              child: FilledButton.icon(
                onPressed: () =>
                    context.go(AppRoutes.editProductDetails(product.id)),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Cập nhật sản phẩm'),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: CircleAvatar(
                backgroundColor: cs.surface.withValues(alpha: .92),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: cs.onSurface, size: 20),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.products);
                    }
                  },
                ),
              ),
            ),
            actions: [
              Consumer<AuthController>(
                builder: (context, auth, _) {
                  final user = auth.currentUser;
                  if (user == null) return const SizedBox.shrink();
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (user.canShop) const CartBadgeIcon(),
                      if (user.canManageProducts)
                        IconButton(
                          tooltip: 'Sửa',
                          onPressed: () => context.go(
                            AppRoutes.editProductDetails(product.id),
                          ),
                          icon: Icon(Icons.edit_outlined, color: cs.primary),
                        ),
                      if (user.canDeleteProducts)
                        IconButton(
                          tooltip: 'Xóa',
                          onPressed: () => _confirmDelete(context, product),
                          icon: Icon(Icons.delete_outline, color: cs.error),
                        ),
                      const SizedBox(width: 4),
                    ],
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: ProductImage(
                imageUrl: product.imageUrl,
                borderRadius: 0,
                width: double.infinity,
                height: double.infinity,
                cacheLogicalWidth: 480,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadii.xxxl),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xxxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusChip(
                        label: product.category.label,
                        background: cs.secondary.withValues(alpha: .15),
                        foreground: cs.secondary,
                      ),
                      StatusChip.productStatus(
                        product.status,
                        brightness: brightness,
                      ),
                      if (product.isActive && !product.isInStock)
                        StatusChip.outOfStock(cs)
                      else if (product.canBePurchased)
                        StatusChip(
                          label: 'Còn ${product.stockQuantity}',
                          background: cs.primary.withValues(alpha: .12),
                          foreground: cs.primary,
                        ),
                      if (product.isActive &&
                          product.isInStock &&
                          product.stockQuantity <= 5)
                        StatusChip(
                          label: 'Sắp hết',
                          background: cs.tertiary.withValues(alpha: .15),
                          foreground: cs.tertiary,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    product.name,
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: .06),
                      borderRadius: AppRadii.borderXl,
                      border: Border.all(
                        color: cs.primary.withValues(alpha: .1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Giá bán trực tuyến',
                          style: tt.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        PriceText(product.price, fontSize: 22),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Thông tin sản phẩm',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    product.description,
                    style: tt.bodyLarge?.copyWith(
                      height: 1.65,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: AppRadii.borderXl,
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: .45),
                      ),
                    ),
                    child: Column(
                      children: [
                        _SpecRow(
                          icon: Icons.qr_code_2_outlined,
                          label: 'Mã SKU',
                          value: product.sku,
                        ),
                        const Divider(height: 24),
                        _SpecRow(
                          icon: Icons.category_outlined,
                          label: 'Danh mục',
                          value: product.category.label,
                        ),
                        const Divider(height: 24),
                        _SpecRow(
                          icon: Icons.inventory_2_outlined,
                          label: 'Tồn kho',
                          value: '${product.stockQuantity} sản phẩm',
                        ),
                        const Divider(height: 24),
                        _SpecRow(
                          icon: Icons.toggle_on_outlined,
                          label: 'Trạng thái',
                          value: product.status.label,
                        ),
                        const Divider(height: 24),
                        _SpecRow(
                          icon: Icons.update_outlined,
                          label: 'Cập nhật',
                          value: formatShortDate(product.updatedAt),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({
    required this.icon,
    required this.label,
    required this.value,
  });

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
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: cs.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _confirmDelete(BuildContext context, Product product) async {
  final ok = await showConfirmDialog(
    context,
    title: 'Xóa sản phẩm?',
    message: 'Sản phẩm "${product.name}" sẽ bị xóa vĩnh viễn.',
    confirmLabel: 'Xóa',
    isDestructive: true,
  );
  if (!ok || !context.mounted) return;
  await context.read<ProductController>().deleteProduct(product.id);
  if (!context.mounted) return;
  context.read<CartController>().remove(product.id);
  context.go(AppRoutes.products);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Đã xóa ${product.name}.'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
