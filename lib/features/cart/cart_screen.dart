import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/cart_item.dart';
import '../../shared/components/price_text.dart';
import '../../shared/components/primary_bottom_bar.dart';
import '../../shared/components/quantity_stepper.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/product_image.dart';
import '../../state/auth_controller.dart';
import '../../state/cart_controller.dart';
import '../../state/order_controller.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _checkingOut = false;

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
                onPressed: cart.isEmpty || _checkingOut
                    ? null
                    : () => _confirmClear(context, cart),
                icon: Icon(
                  Icons.delete_sweep_outlined,
                  color: cs.error,
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
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              140,
            ),
            itemCount: cart.items.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CartTile(item: cart.items[i]),
            ),
          );
        },
      ),
      bottomNavigationBar: Consumer<CartController>(
        builder: (context, cart, _) {
          if (cart.isEmpty) return const SizedBox.shrink();

          return PrimaryBottomBar(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TỔNG CỘNG',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: cs.onSurfaceVariant,
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
                    PriceText(cart.totalPrice, fontSize: 20),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton(
                  onPressed: _checkingOut ? null : () => _checkout(context),
                  child: _checkingOut
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: cs.onPrimary,
                          ),
                        )
                      : const Row(
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
          );
        },
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, CartController cart) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Xóa giỏ hàng?',
      message: 'Toàn bộ sản phẩm trong giỏ hàng sẽ bị xóa.',
      confirmLabel: 'Xóa tất cả',
      isDestructive: true,
    );
    if (ok) cart.clear();
  }

  Future<void> _checkout(BuildContext context) async {
    if (_checkingOut) return;

    final cart = context.read<CartController>();
    final user = context.read<AuthController>().currentUser;
    final orderController = context.read<OrderController>();
    final messenger = ScaffoldMessenger.of(context);
    if (user == null || cart.isEmpty) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            MediaQuery.paddingOf(ctx).bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Xác nhận đặt hàng',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Bạn muốn mua ${cart.totalQuantity} sản phẩm với tổng '
                '${formatCurrency(cart.totalPrice)}?',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(ctx, true);
                },
                child: const Text('Xác nhận đặt'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _checkingOut = true);

    try {
      final items = List<CartItem>.from(cart.items);

      // Stock + order are written in one Firestore transaction (no orphan stock).
      final order = await orderController.checkout(user: user, items: items);
      cart.clear();

      if (!context.mounted) return;
      final navigator = Navigator.of(context);
      final router = GoRouter.of(context);
      final orderLabel = order.id.split('-').last;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isDismissible: true,
        builder: (ctx) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              MediaQuery.paddingOf(ctx).bottom + AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 48,
                  color: Theme.of(ctx).colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Đã gửi đơn thành công!',
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Đơn #$orderLabel đang ở trạng thái "Đã gửi đơn".\n'
                  'Cửa hàng sẽ xác nhận khi nhận đơn — bạn có thể theo dõi trong mục Đơn.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () {
                    navigator.pop();
                    router.go(AppRoutes.orders);
                  },
                  child: const Text('Xem đơn hàng'),
                ),
                TextButton(
                  onPressed: () {
                    navigator.pop();
                    router.go(AppRoutes.products);
                  },
                  child: const Text('Tiếp tục mua sắm'),
                ),
              ],
            ),
          );
        },
      );
    } catch (e, st) {
      debugPrint('checkout_failed err=$e\n$st');
      if (!mounted) return;
      final message = _checkoutErrorMessage(e);
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  String _checkoutErrorMessage(Object e) {
    final raw = e.toString();
    if (raw.contains('permission-denied') ||
        raw.contains('PERMISSION_DENIED')) {
      return 'Không có quyền tạo đơn (permission-denied). '
          'Hãy đăng nhập lại bằng tài khoản customer và thử lại.';
    }
    if (raw.contains('Không đủ tồn kho') ||
        raw.contains('insufficient-stock') ||
        raw.contains('Sản phẩm không tồn tại')) {
      return raw.replaceFirst('Bad state: ', '').replaceFirst('Exception: ', '');
    }
    if (raw.contains('email')) {
      return 'Phiên đăng nhập thiếu email. Vui lòng đăng xuất và đăng nhập lại.';
    }
    // Surface a readable message for lab debugging (not only generic copy).
    final short = raw
        .replaceFirst('Bad state: ', '')
        .replaceFirst('Exception: ', '')
        .replaceFirst('[cloud_firestore/permission-denied] ', '');
    if (short.length < 160) return 'Không thể đặt hàng: $short';
    return 'Không thể đặt hàng. Vui lòng thử lại.';
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
    final cart = context.read<CartController>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImage(
              imageUrl: product.imageUrl,
              width: 84,
              height: 84,
              borderRadius: 12,
              cacheLogicalWidth: 168,
            ),
            const SizedBox(width: AppSpacing.sm),
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
                  const SizedBox(height: AppSpacing.sm),
                  QuantityStepper(
                    quantity: item.quantity,
                    max: product.stockQuantity,
                    onDecrement: () => cart.decrement(product.id),
                    onIncrement: () {
                      final ok = cart.increment(product.id);
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
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PriceText(item.totalPrice, fontSize: 14),
                const SizedBox(height: AppSpacing.sm),
                IconButton(
                  tooltip: 'Gỡ khỏi giỏ hàng',
                  onPressed: () => cart.remove(product.id),
                  icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
                  style: IconButton.styleFrom(
                    backgroundColor: cs.errorContainer.withValues(alpha: .3),
                    minimumSize: const Size(44, 44),
                    padding: EdgeInsets.zero,
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
