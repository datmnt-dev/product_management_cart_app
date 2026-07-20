import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/product_model.dart';
import '../../state/cart_controller.dart';
import '../../state/product_controller.dart';
import '../widgets/product_image.dart';
import 'price_text.dart';
import 'status_chip.dart';

/// Catalog grid card with smart badges and role-aware actions.
class ProductCard extends StatefulWidget {
  const ProductCard({
    required this.product,
    required this.canManage,
    required this.canDelete,
    required this.canShop,
    super.key,
  });

  final Product product;
  final bool canManage;
  final bool canDelete;
  final bool canShop;

  static bool isNew(Product product, {Duration window = const Duration(days: 7)}) {
    return DateTime.now().difference(product.createdAt) <= window;
  }

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final product = widget.product;
    final brightness = Theme.of(context).brightness;
    final showNew = ProductCard.isNew(product);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.fastCurve,
        child: Card(
          elevation: _isHovered ? 3 : 0,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.go(AppRoutes.productDetails(product.id)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ProductImage(
                        imageUrl: product.imageUrl,
                        borderRadius: 0,
                        width: double.infinity,
                        height: double.infinity,
                        cacheLogicalWidth: 220,
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            if (showNew) StatusChip.newBadge(cs),
                            if (widget.canManage &&
                                product.status != ProductStatus.active)
                              StatusChip.productStatus(
                                product.status,
                                brightness: brightness,
                              ),
                            if (!product.isInStock && product.isActive)
                              StatusChip.outOfStock(cs),
                          ],
                        ),
                      ),
                      if (widget.canManage)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Material(
                            color: cs.surface.withValues(alpha: .92),
                            shape: const CircleBorder(),
                            child: PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.more_vert,
                                size: 18,
                                color: cs.onSurface,
                              ),
                              onSelected: (action) {
                                if (action == 'edit') {
                                  context.go(
                                    AppRoutes.editProductDetails(product.id),
                                  );
                                }
                                if (action == 'delete') {
                                  _confirmDelete(context, product);
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
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm - 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.category.label} · '
                        '${product.isInStock ? 'Kho ${product.stockQuantity}' : 'Hết hàng'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Expanded(child: PriceText(product.price, fontSize: 13)),
                          if (widget.canShop)
                            _AddToCartButton(product: product),
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

class _AddToCartButton extends StatelessWidget {
  const _AddToCartButton({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = product.canBePurchased;

    return Semantics(
      button: true,
      enabled: enabled,
      label: enabled
          ? 'Thêm ${product.name} vào giỏ'
          : '${product.name} không thể mua',
      child: Tooltip(
        message: enabled ? 'Thêm vào giỏ' : 'Không thể mua',
        child: Material(
          color: enabled
              ? cs.primary.withValues(alpha: .1)
              : cs.surfaceContainerHighest,
          borderRadius: AppRadii.borderMd,
          child: InkWell(
            borderRadius: AppRadii.borderMd,
            onTap: enabled
                ? () {
                    final added =
                        context.read<CartController>().addProduct(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          added
                              ? 'Đã thêm ${product.name} vào giỏ.'
                              : '${product.name} hiện không đủ hàng.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                : null,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.add_shopping_cart_rounded,
                size: 18,
                color: enabled ? cs.primary : cs.onSurfaceVariant,
              ),
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

  if (ok == true && context.mounted) {
    await context.read<ProductController>().deleteProduct(product.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa ${product.name}.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
