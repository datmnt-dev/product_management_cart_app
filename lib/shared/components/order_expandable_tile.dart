import 'package:flutter/material.dart';

import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/order_model.dart';
import '../widgets/product_image.dart';
import 'price_text.dart';

/// Expandable order card with line-item thumbs.
class OrderExpandableTile extends StatelessWidget {
  const OrderExpandableTile({required this.order, super.key});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final shortId = order.id.split('-').last.toUpperCase();
    final firstImage = order.items.isNotEmpty ? order.items.first.imageUrl : '';

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
          padding: const EdgeInsets.only(top: 4),
          child: Row(
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: .1),
                  borderRadius: AppRadii.borderSm,
                ),
                child: const Text(
                  'Hoàn thành',
                  style: TextStyle(
                    color: Color(0xFF16A34A),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
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
        ],
      ),
    );
  }
}
