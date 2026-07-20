import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/cart_item.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/product_image.dart';
import '../../state/auth_controller.dart';
import '../../state/cart_controller.dart';
import '../../state/order_controller.dart';
import '../../state/product_controller.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Consumer<CartController>(
          builder: (_, cart, child) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Giỏ hàng của tôi'),
              if (!cart.isEmpty)
                Text(
                  '${cart.totalQuantity} mặt hàng trong danh sách',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          Consumer<CartController>(
            builder: (context, cart, _) {
              return IconButton(
                tooltip: 'Xóa toàn bộ giỏ hàng',
                onPressed: cart.isEmpty
                    ? null
                    : () => _confirmClear(context, cart),
                icon: const Icon(
                  Icons.delete_sweep_outlined,
                  color: Colors.red,
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<CartController>(
        builder: (context, cart, _) {
          if (cart.isEmpty) {
            return EmptyState(
              icon: Icons.shopping_basket_outlined,
              title: 'Giỏ hàng của bạn đang trống',
              message:
                  'Hãy khám phá cửa hàng và chọn những món đồ bạn yêu thích nhé.',
              action: FilledButton.icon(
                onPressed: () => context.go(AppRoutes.products),
                icon: const Icon(Icons.storefront),
                label: const Text('Bắt đầu mua sắm'),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
            itemCount: cart.items.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CartTile(item: cart.items[i]),
            ),
          );
        },
      ),
      bottomNavigationBar: Consumer<CartController>(
        builder: (context, cart, _) {
          if (cart.isEmpty) return const SizedBox.shrink();

          return Container(
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                top: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: .25),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .04),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TỔNG CỘNG',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${cart.totalQuantity} sản phẩm',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        formatCurrency(cart.totalPrice),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: cs.primary,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () => _checkout(context),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_checkout),
                        SizedBox(width: 8),
                        Text('Đặt hàng ngay'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CartTile extends StatelessWidget {
  const _CartTile({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImage(
              imageUrl: product.imageUrl,
              width: 84,
              height: 84,
              borderRadius: 12,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatCurrency(product.price),
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quantity Stepper
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: .5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _StepperBtn(
                          icon: Icons.remove,
                          onPressed: () => context
                              .read<CartController>()
                              .decrement(product.id),
                        ),
                        Container(
                          width: 38,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.symmetric(
                              vertical: BorderSide(
                                color: cs.outlineVariant.withValues(alpha: .5),
                              ),
                            ),
                          ),
                          child: Text(
                            '${item.quantity}',
                            style: tt.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _StepperBtn(
                          icon: Icons.add,
                          onPressed: () {
                            final ok = context.read<CartController>().increment(
                              product.id,
                            );
                            if (!ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${product.name} chỉ còn ${product.stockQuantity} sản phẩm.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCurrency(item.totalPrice),
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 14),
                IconButton(
                  tooltip: 'Gỡ khỏi giỏ hàng',
                  onPressed: () =>
                      context.read<CartController>().remove(product.id),
                  icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
                  style: IconButton.styleFrom(
                    backgroundColor: cs.errorContainer.withValues(alpha: .3),
                    minimumSize: const Size(32, 32),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperBtn extends StatelessWidget {
  const _StepperBtn({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
      ),
    );
  }
}

Future<void> _confirmClear(BuildContext context, CartController cart) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Xóa giỏ hàng?'),
      content: const Text('Toàn bộ sản phẩm trong giỏ hàng sẽ bị xóa.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Xóa tất cả'),
        ),
      ],
    ),
  );
  if (ok == true) {
    cart.clear();
  }
}

Future<void> _checkout(BuildContext context) async {
  final cart = context.read<CartController>();
  final user = context.read<AuthController>().currentUser;
  final productController = context.read<ProductController>();
  final orderController = context.read<OrderController>();
  final messenger = ScaffoldMessenger.of(context);
  if (user == null || cart.isEmpty) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Xác nhận đặt hàng'),
      content: Text(
        'Bạn muốn mua ${cart.totalQuantity} sản phẩm với tổng số tiền '
        '${formatCurrency(cart.totalPrice)} chứ?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Quay lại'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Xác nhận đặt'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  final items = List<CartItem>.from(cart.items);
  final quantities = {for (final item in items) item.product.id: item.quantity};
  final hasStock = await productController.reduceStock(quantities);
  if (!hasStock || !context.mounted) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Một số sản phẩm đã hết hàng hoặc không đủ số lượng.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  final order = await orderController.checkout(user: user, items: items);
  cart.clear();

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Đơn hàng #${order.id.split('-').last} đã được tạo thành công!',
      ),
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: 'Xem đơn hàng',
        textColor: Theme.of(context).colorScheme.secondary,
        onPressed: () => context.go(AppRoutes.orders),
      ),
    ),
  );
}
