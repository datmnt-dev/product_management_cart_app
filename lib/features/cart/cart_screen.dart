import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../data/models/cart_item.dart';
import '../../data/models/coupon_model.dart';
import '../../data/models/order_model.dart';
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
                icon: Icon(Icons.delete_sweep_outlined, color: cs.error),
              );
            },
          ),
        ],
      ),
      // Checkout bar lives in body (Column) so it stacks cleanly above shell nav.
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

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.xs,
                        AppSpacing.md,
                        AppSpacing.md,
                      ),
                      itemCount: cart.items.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CartTile(item: cart.items[i]),
                      ),
                    ),
                  ),
                  PrimaryBottomBar(
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
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _checkingOut
                                ? null
                                : () => _checkout(context),
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
                        ),
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

    final shipping = await showModalBottomSheet<_CheckoutPayload>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return _CheckoutSheet(
          totalQuantity: cart.totalQuantity,
          totalPrice: cart.totalPrice,
          defaultName: user.fullName,
          onPreviewCoupon: (code) {
            return orderController.previewCoupon(
              code: code,
              subtotal: cart.totalPrice,
            );
          },
        );
      },
    );

    if (shipping == null || !mounted) return;

    setState(() => _checkingOut = true);

    try {
      final items = List<CartItem>.from(cart.items);

      // Stock + order are written in one Firestore transaction (no orphan stock).
      final order = await orderController.checkout(
        user: user,
        items: items,
        customerName: shipping.name,
        phone: shipping.phone,
        shippingAddress: shipping.address,
        note: shipping.note,
        paymentMethod: shipping.paymentMethod,
        couponCode: shipping.couponCode,
      );
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
          final discountLine = order.hasDiscount
              ? 'Mã ${order.couponCode} giảm ${formatCurrency(order.discountAmount)}.\n'
              : '';
          final successMessage =
              'Đơn #$orderLabel đang ở trạng thái "Đã gửi đơn".\n'
              '$discountLine'
              '${order.paymentMethod.shortLabel} · ${order.paymentStatus.label}.\n'
              'Cửa hàng sẽ xác nhận khi nhận đơn — bạn có thể theo dõi trong mục Đơn.';
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
                  style: Theme.of(
                    ctx,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(successMessage, textAlign: TextAlign.center),
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
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
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
      return raw
          .replaceFirst('Bad state: ', '')
          .replaceFirst('Exception: ', '');
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

class _CheckoutPayload {
  const _CheckoutPayload({
    required this.name,
    required this.phone,
    required this.address,
    required this.note,
    required this.paymentMethod,
    required this.couponCode,
  });

  final String name;
  final String phone;
  final String address;
  final String note;
  final PaymentMethod paymentMethod;
  final String couponCode;
}

class _CheckoutSheet extends StatefulWidget {
  const _CheckoutSheet({
    required this.totalQuantity,
    required this.totalPrice,
    required this.defaultName,
    required this.onPreviewCoupon,
  });

  final int totalQuantity;
  final double totalPrice;
  final String defaultName;
  final Future<AppliedCoupon> Function(String code) onPreviewCoupon;

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _note;
  late final TextEditingController _coupon;
  PaymentMethod _paymentMethod = PaymentMethod.cashOnDelivery;
  AppliedCoupon? _appliedCoupon;
  bool _checkingCoupon = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.defaultName);
    _phone = TextEditingController();
    _address = TextEditingController();
    _note = TextEditingController();
    _coupon = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _note.dispose();
    _coupon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final discount = _appliedCoupon?.discountAmount ?? 0;
    final finalTotal = (widget.totalPrice - discount).clamp(
      0,
      widget.totalPrice,
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        MediaQuery.paddingOf(context).bottom + AppSpacing.lg + bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Thông tin giao hàng',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${widget.totalQuantity} sản phẩm · '
                '${formatCurrency(finalTotal.toDouble())}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Họ tên người nhận',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => Validators.requiredText(v, 'họ tên'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: Validators.phone,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _address,
                textInputAction: TextInputAction.next,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ giao hàng',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  alignLabelWithHint: true,
                ),
                validator: Validators.shippingAddress,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _note,
                textInputAction: TextInputAction.done,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (tuỳ chọn)',
                  prefixIcon: Icon(Icons.sticky_note_2_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Mã giảm giá',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _coupon,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Coupon code',
                        prefixIcon: const Icon(Icons.confirmation_num_outlined),
                        suffixIcon: _appliedCoupon == null
                            ? null
                            : IconButton(
                                tooltip: 'Bỏ mã',
                                onPressed: _clearCoupon,
                                icon: const Icon(Icons.close),
                              ),
                      ),
                      onChanged: (_) {
                        if (_appliedCoupon != null) _discardAppliedCoupon();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: _checkingCoupon ? null : _applyCoupon,
                    child: _checkingCoupon
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Áp dụng'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _CheckoutTotalBreakdown(
                subtotal: widget.totalPrice,
                appliedCoupon: _appliedCoupon,
                total: finalTotal.toDouble(),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Phương thức thanh toán',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final method in PaymentMethod.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PaymentMethodTile(
                    method: method,
                    selected: _paymentMethod == method,
                    onTap: () => setState(() => _paymentMethod = method),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  HapticFeedback.mediumImpact();
                  Navigator.pop(
                    context,
                    _CheckoutPayload(
                      name: _name.text.trim(),
                      phone: _phone.text.trim(),
                      address: _address.text.trim(),
                      note: _note.text.trim(),
                      paymentMethod: _paymentMethod,
                      couponCode: _appliedCoupon?.code ?? '',
                    ),
                  );
                },
                child: const Text('Xác nhận đặt hàng'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applyCoupon() async {
    final code = _coupon.text.trim();
    if (code.isEmpty) return;
    setState(() => _checkingCoupon = true);
    try {
      final applied = await widget.onPreviewCoupon(code);
      if (!mounted) return;
      setState(() {
        _appliedCoupon = applied;
        _coupon.text = applied.code;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Bad state: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _checkingCoupon = false);
    }
  }

  void _clearCoupon() {
    setState(() {
      _appliedCoupon = null;
      _coupon.clear();
    });
  }

  void _discardAppliedCoupon() {
    setState(() => _appliedCoupon = null);
  }
}

class _CheckoutTotalBreakdown extends StatelessWidget {
  const _CheckoutTotalBreakdown({
    required this.subtotal,
    required this.appliedCoupon,
    required this.total,
  });

  final double subtotal;
  final AppliedCoupon? appliedCoupon;
  final double total;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _totalRow('Tạm tính', formatCurrency(subtotal)),
          if (appliedCoupon != null) ...[
            const SizedBox(height: 6),
            _totalRow(
              'Giảm ${appliedCoupon!.code}',
              '-${formatCurrency(appliedCoupon!.discountAmount)}',
              color: Colors.green,
            ),
          ],
          const Divider(height: 16),
          _totalRow(
            'Thanh toán',
            formatCurrency(total),
            isStrong: true,
            color: cs.primary,
          ),
        ],
      ),
    );
  }

  Widget _totalRow(
    String label,
    String value, {
    bool isStrong = false,
    Color? color,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isStrong ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w900, color: color),
        ),
      ],
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? cs.primaryContainer.withValues(alpha: .45)
          : cs.surfaceContainerHighest.withValues(alpha: .25),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? cs.primary : cs.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(method.icon, color: selected ? cs.primary : cs.onSurface),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.label,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      method.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
