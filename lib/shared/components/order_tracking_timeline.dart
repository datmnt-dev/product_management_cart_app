import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/order_model.dart';

/// Vertical timeline of order status history + remaining pipeline steps.
class OrderTrackingTimeline extends StatelessWidget {
  const OrderTrackingTimeline({required this.order, super.key});

  final OrderModel order;

  static const pipeline = <OrderStatus>[
    OrderStatus.placed,
    OrderStatus.confirmed,
    OrderStatus.preparing,
    OrderStatus.shipping,
    OrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final historyByStatus = {
      for (final e in order.statusHistory) e.status: e,
    };
    final cancelled = order.status == OrderStatus.cancelled;

    final steps = cancelled
        ? [
            ...order.statusHistory.map((e) => e.status),
            if (!order.statusHistory.any((e) => e.status == OrderStatus.cancelled))
              OrderStatus.cancelled,
          ]
        : pipeline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theo dõi trạng thái',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...List.generate(steps.length, (index) {
          final status = steps[index];
          final event = historyByStatus[status];
          final currentIdx = pipeline.indexOf(order.status);
          final stepIdx = pipeline.indexOf(status);
          final isDone = cancelled
              ? event != null || status == OrderStatus.cancelled
              : (stepIdx >= 0 && currentIdx >= 0 && stepIdx <= currentIdx);
          final isCurrent = status == order.status;
          final color = isCurrent
              ? status.color
              : (isDone ? status.color.withValues(alpha: .7) : cs.outlineVariant);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDone || isCurrent
                            ? status.color.withValues(alpha: .15)
                            : cs.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 1.5),
                      ),
                      child: Icon(
                        status.icon,
                        size: 14,
                        color: isDone || isCurrent
                            ? status.color
                            : cs.onSurfaceVariant,
                      ),
                    ),
                    if (index < steps.length - 1)
                      Container(
                        width: 2,
                        height: 22,
                        color: isDone
                            ? status.color.withValues(alpha: .35)
                            : cs.outlineVariant.withValues(alpha: .4),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: isDone || isCurrent
                              ? cs.onSurface
                              : cs.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        event?.note.isNotEmpty == true
                            ? event!.note
                            : status.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                      if (event != null)
                        Text(
                          '${formatDate(event.at)}'
                          '${event.byEmail.isNotEmpty ? ' · ${event.byEmail}' : ''}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurfaceVariant.withValues(alpha: .85),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
