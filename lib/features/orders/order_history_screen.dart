import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/load_status.dart';
import '../../data/models/order_model.dart';
import '../../shared/components/order_expandable_tile.dart';
import '../../shared/widgets/app_error_state.dart';
import '../../shared/widgets/app_loading_state.dart';
import '../../shared/widgets/empty_state.dart';
import '../../state/auth_controller.dart';
import '../../state/order_controller.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử đơn hàng'),
      ),
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

          final orders = user == null
              ? <OrderModel>[]
              : controller.ordersForEmail(user.email);

          if (orders.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Chưa có đơn hàng nào',
              message:
                  'Hãy bắt đầu đặt hàng và các hóa đơn của bạn sẽ được hiển thị tại đây.',
              action: FilledButton.icon(
                onPressed: () => context.go(AppRoutes.products),
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('Xem sản phẩm mua sắm'),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.xxxl,
            ),
            itemCount: orders.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: _Summary(orders: orders),
                );
              }
              if (index == 1) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    'Danh sách hóa đơn',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
              }
              final order = orders[index - 2];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OrderExpandableTile(order: order),
              );
            },
          );
        },
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.orders});
  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final total = orders.fold<double>(0, (v, o) => v + o.totalAmount);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.secondary, cs.secondary.withValues(alpha: .85)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.secondary.withValues(alpha: .2),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.receipt_long,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tổng cộng ${orders.length} hóa đơn',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Đã chi tiêu: ${formatCurrency(total)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .9),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
