import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/load_status.dart';
import '../../data/models/order_model.dart';
import '../../shared/components/order_expandable_tile.dart';
import '../../shared/widgets/app_error_state.dart';
import '../../shared/widgets/app_loading_state.dart';
import '../../shared/widgets/empty_state.dart';
import '../../state/auth_controller.dart';
import '../../state/order_controller.dart';

/// Customer-only order history.
///
/// Staff order operations live in [StatisticsScreen] and `/orders` is guarded
/// to shoppers in the router.
class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CustomerOrderHistory();
  }
}

// ── Customer history ──────────────────────────────────────────────────────────

class _CustomerOrderHistory extends StatelessWidget {
  const _CustomerOrderHistory();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử đơn hàng')),
      body: Consumer<OrderController>(
        builder: (context, controller, _) {
          if (controller.status == LoadStatus.loading &&
              controller.orders.isEmpty) {
            return const AppLoadingState(message: 'Đang tải đơn hàng...');
          }

          if (controller.hasError && controller.orders.isEmpty) {
            return AppErrorState(
              title: 'Không tải được đơn hàng',
              message:
                  controller.errorMessage ??
                  'Không thể tải đơn hàng. Kiểm tra kết nối mạng và thử lại.',
              onRetry: controller.retry,
            );
          }

          final allMine = user == null
              ? <OrderModel>[]
              : controller.ordersForEmail(user.email);

          if (allMine.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Chưa có đơn hàng nào',
              message:
                  'Hãy bắt đầu đặt hàng và theo dõi trạng thái đơn tại đây '
                  '(đã gửi → shop nhận → chuẩn bị → giao → hoàn thành).',
              action: FilledButton.icon(
                onPressed: () => context.go(AppRoutes.products),
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('Xem sản phẩm mua sắm'),
              ),
            );
          }

          final statusFilter = controller.statusFilter;
          final orders = statusFilter == null
              ? allMine
              : allMine.where((o) => o.status == statusFilter).toList();

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.xxxl,
                ),
                children: [
                  _CustomerSummary(orders: allMine),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Lọc theo trạng thái',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _StatusFilterBar(
                    selected: statusFilter,
                    counts: {
                      for (final s in OrderStatus.values)
                        s: allMine.where((o) => o.status == s).length,
                    },
                    onSelected: controller.setStatusFilter,
                    showAllCount: allMine.length,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Đơn của tôi (${orders.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (orders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: EmptyState(
                        icon: Icons.filter_alt_off_outlined,
                        title: 'Không có đơn phù hợp',
                        message:
                            'Thử đổi bộ lọc trạng thái để xem các đơn khác.',
                      ),
                    )
                  else
                    ...orders.map(
                      (o) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: OrderExpandableTile(order: o),
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

class _CustomerSummary extends StatelessWidget {
  const _CustomerSummary({required this.orders});
  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = orders.where((o) => !o.status.isTerminal).length;
    final done = orders.where((o) => o.status == OrderStatus.delivered).length;
    final cancelled = orders
        .where((o) => o.status == OrderStatus.cancelled)
        .length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: .35),
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .4)),
      ),
      child: Row(
        children: [
          _MiniStat(label: 'Tổng', value: '${orders.length}'),
          _MiniStat(label: 'Đang xử lý', value: '$active'),
          _MiniStat(label: 'Hoàn thành', value: '$done'),
          _MiniStat(label: 'Đã hủy', value: '$cancelled'),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared status filter chips ────────────────────────────────────────────────

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({
    required this.selected,
    required this.onSelected,
    this.counts = const {},
    this.showAllCount,
  });

  final OrderStatus? selected;
  final ValueChanged<OrderStatus?> onSelected;
  final Map<OrderStatus, int> counts;
  final int? showAllCount;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                showAllCount == null ? 'Tất cả' : 'Tất cả ($showAllCount)',
              ),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final status in OrderStatus.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: Icon(status.icon, size: 16, color: status.color),
                label: Text(
                  counts.containsKey(status)
                      ? '${status.shortLabel} (${counts[status]})'
                      : status.shortLabel,
                ),
                selected: selected == status,
                onSelected: (_) =>
                    onSelected(selected == status ? null : status),
              ),
            ),
        ],
      ),
    );
  }
}
