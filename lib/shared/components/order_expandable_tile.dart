import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/order_model.dart';
import '../../data/models/user_model.dart';
import '../../state/auth_controller.dart';
import '../../state/order_controller.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/product_image.dart';
import 'order_status_chip.dart';
import 'order_tracking_timeline.dart';
import 'price_text.dart';

/// Expandable order card with tracking + role actions.
class OrderExpandableTile extends StatelessWidget {
  const OrderExpandableTile({
    required this.order,
    this.showCustomerEmail = false,
    super.key,
  });

  final OrderModel order;
  final bool showCustomerEmail;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final shortId = order.id.split('-').last.toUpperCase();
    final firstImage = order.items.isNotEmpty ? order.items.first.imageUrl : '';
    final user = context.watch<AuthController>().currentUser;
    final orders = context.watch<OrderController>();

    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: ClipRRect(
          borderRadius: AppRadii.borderMd,
          child: ProductImage(
            imageUrl: firstImage,
            width: 44,
            height: 44,
            borderRadius: AppRadii.md,
            cacheLogicalWidth: 88,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Đơn hàng #$shortId',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
            PriceText(order.totalAmount, fontSize: 14),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 12,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      formatDate(order.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  OrderStatusChip(status: order.status, compact: true),
                ],
              ),
              if (showCustomerEmail) ...[
                const SizedBox(height: 4),
                Text(
                  order.userEmail,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        children: [
          const Divider(height: 20),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  ProductImage(
                    imageUrl: item.imageUrl,
                    width: 40,
                    height: 40,
                    borderRadius: AppRadii.sm,
                    cacheLogicalWidth: 80,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    '${item.quantity} × ${formatCurrency(item.unitPrice)}',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (order.hasDiscount) ...[
            const SizedBox(height: AppSpacing.xs),
            _DiscountBlock(order: order),
          ],
          if (order.hasShippingInfo || order.customerName.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _ShippingBlock(order: order),
          ],
          const SizedBox(height: AppSpacing.sm),
          _PaymentBlock(order: order),
          const SizedBox(height: AppSpacing.sm),
          OrderTrackingTimeline(order: order),
          if (user != null) ...[
            const SizedBox(height: AppSpacing.md),
            _OrderActions(order: order, user: user, busy: orders.isUpdating),
          ],
        ],
      ),
    );
  }
}

class _DiscountBlock extends StatelessWidget {
  const _DiscountBlock({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: .08),
        borderRadius: AppRadii.borderMd,
      ),
      child: Column(
        children: [
          _row('Tạm tính', formatCurrency(order.effectiveSubtotal), cs),
          const SizedBox(height: 4),
          _row(
            'Mã ${order.couponCode}',
            '-${formatCurrency(order.discountAmount)}',
            cs,
            color: Colors.green,
          ),
          const Divider(height: 14),
          _row(
            'Thanh toán',
            formatCurrency(order.totalAmount),
            cs,
            strong: true,
            color: cs.primary,
          ),
        ],
      ),
    );
  }

  Widget _row(
    String label,
    String value,
    ColorScheme cs, {
    bool strong = false,
    Color? color,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: color ?? cs.onSurface,
          ),
        ),
      ],
    );
  }
}

class _PaymentBlock extends StatelessWidget {
  const _PaymentBlock({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: order.paymentStatus.color.withValues(alpha: .08),
        borderRadius: AppRadii.borderMd,
        border: Border.all(
          color: order.paymentStatus.color.withValues(alpha: .22),
        ),
      ),
      child: Row(
        children: [
          Icon(order.paymentMethod.icon, size: 20, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.paymentMethod.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  order.paymentMethod.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Chip(
            avatar: Icon(
              order.paymentStatus.icon,
              size: 14,
              color: order.paymentStatus.color,
            ),
            label: Text(order.paymentStatus.shortLabel),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _ShippingBlock extends StatelessWidget {
  const _ShippingBlock({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rows = <Widget>[];
    if (order.customerName.trim().isNotEmpty) {
      rows.add(_line(Icons.person_outline, order.customerName, cs));
    }
    if (order.phone.trim().isNotEmpty) {
      rows.add(_line(Icons.phone_outlined, order.phone, cs));
    }
    if (order.shippingAddress.trim().isNotEmpty) {
      rows.add(_line(Icons.location_on_outlined, order.shippingAddress, cs));
    }
    if (order.note.trim().isNotEmpty) {
      rows.add(_line(Icons.sticky_note_2_outlined, order.note, cs));
    }
    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: .45),
        borderRadius: AppRadii.borderMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Giao hàng',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 6),
          ...rows,
        ],
      ),
    );
  }

  Widget _line(IconData icon, String text, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderActions extends StatelessWidget {
  const _OrderActions({
    required this.order,
    required this.user,
    required this.busy,
  });

  final OrderModel order;
  final AppUser user;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final isStaff = user.canViewRevenue;
    final controller = context.read<OrderController>();
    final messenger = ScaffoldMessenger.of(context);

    Future<void> run(Future<OrderModel> Function() action, String okMsg) async {
      try {
        await action();
        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text(okMsg), behavior: SnackBarBehavior.floating),
        );
      } catch (e) {
        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Bad state: ', '')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    final actions = <Widget>[];

    if (isStaff) {
      if (order.canStaffMarkPaid) {
        actions.add(
          FilledButton.icon(
            onPressed: busy
                ? null
                : () => run(
                    () => controller.markPaid(order, user),
                    'Đã xác nhận thanh toán',
                  ),
            icon: const Icon(Icons.verified_outlined, size: 18),
            label: const Text('Xác nhận thanh toán'),
          ),
        );
      }
      if (order.canStaffRefund) {
        actions.add(
          OutlinedButton.icon(
            onPressed: busy
                ? null
                : () async {
                    final ok = await showConfirmDialog(
                      context,
                      title: 'Hoàn tiền đơn hàng?',
                      message:
                          'Đơn #${order.id.split('-').last} sẽ chuyển trạng thái thanh toán sang đã hoàn tiền.',
                      confirmLabel: 'Hoàn tiền',
                    );
                    if (!ok || !context.mounted) return;
                    await run(
                      () => controller.refundPayment(order, user),
                      'Đã hoàn tiền đơn hàng',
                    );
                  },
            icon: const Icon(Icons.currency_exchange_outlined, size: 18),
            label: const Text('Hoàn tiền'),
          ),
        );
      }
      final nextLabel = order.status.nextStaffActionLabel;
      if (nextLabel != null) {
        actions.add(
          FilledButton.icon(
            onPressed: busy
                ? null
                : () => run(
                    () => controller.advanceStaff(order, user),
                    nextLabel,
                  ),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(nextLabel),
          ),
        );
      }
      if (OrderTransitions.canStaffCancel(order.status)) {
        actions.add(
          OutlinedButton.icon(
            onPressed: busy
                ? null
                : () async {
                    final ok = await showConfirmDialog(
                      context,
                      title: 'Hủy đơn hàng?',
                      message:
                          'Đơn #${order.id.split('-').last} sẽ chuyển sang trạng thái đã hủy.',
                      confirmLabel: 'Hủy đơn',
                      isDestructive: true,
                    );
                    if (!ok || !context.mounted) return;
                    await run(
                      () => controller.cancelOrder(order, user),
                      'Đã hủy đơn hàng',
                    );
                  },
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('Hủy đơn'),
          ),
        );
      }
    } else {
      // Customer actions
      if (order.canCustomerConfirmReceived) {
        actions.add(
          FilledButton.icon(
            onPressed: busy
                ? null
                : () => run(
                    () => controller.customerConfirmReceived(order, user),
                    'Cảm ơn bạn! Đã xác nhận nhận hàng.',
                  ),
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Xác nhận đã nhận hàng'),
          ),
        );
      }
      if (order.canCustomerCancel) {
        actions.add(
          OutlinedButton.icon(
            onPressed: busy
                ? null
                : () async {
                    final ok = await showConfirmDialog(
                      context,
                      title: 'Hủy đơn hàng?',
                      message:
                          'Bạn chỉ có thể hủy khi shop chưa giao hàng. Tiếp tục?',
                      confirmLabel: 'Hủy đơn',
                      isDestructive: true,
                    );
                    if (!ok || !context.mounted) return;
                    await run(
                      () => controller.cancelOrder(order, user),
                      'Đã gửi yêu cầu hủy đơn',
                    );
                  },
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('Hủy đơn'),
          ),
        );
      }
    }

    if (actions.isEmpty) {
      return Text(
        order.status.description,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          actions[i],
        ],
      ],
    );
  }
}
