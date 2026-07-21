import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/load_status.dart';
import '../../data/models/seller_fulfillment.dart';
import '../../data/services/firestore_database.dart';
import '../../shared/widgets/app_error_state.dart';
import '../../shared/widgets/app_loading_state.dart';
import '../../shared/widgets/empty_state.dart';
import '../../state/auth_controller.dart';
import '../../state/product_controller.dart';
import 'seller_dashboard_metrics.dart';

class SellerDashboardScreen extends StatelessWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthController>().currentUser!;
    final database = context.read<FirestoreDatabase>();
    final products = context.watch<ProductController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tổng quan shop'),
        actions: [
          IconButton(
            tooltip: 'Đơn cần giao',
            onPressed: () => context.go(AppRoutes.fulfillments),
            icon: const Icon(Icons.local_shipping_outlined),
          ),
        ],
      ),
      body: StreamBuilder<List<SellerFulfillment>>(
        stream: database.watchSellerFulfillments(user.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const AppErrorState(
              title: 'Không tải được tổng quan shop',
              message: 'Kiểm tra kết nối mạng rồi thử lại.',
            );
          }
          if (!snapshot.hasData ||
              (products.status == LoadStatus.loading &&
                  products.products.isEmpty)) {
            return const AppLoadingState(message: 'Đang tải dữ liệu shop...');
          }
          if (products.hasError && products.products.isEmpty) {
            return AppErrorState(
              title: 'Không tải được kho hàng',
              message: products.errorMessage ?? 'Vui lòng thử lại.',
              onRetry: products.retry,
            );
          }

          final metrics = SellerDashboardMetrics.fromData(
            products: products.products
                .where((product) => product.sellerId == user.id)
                .toList(),
            fulfillments: snapshot.data!,
          );
          return _DashboardBody(metrics: metrics, shopName: user.shopName);
        },
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.metrics, required this.shopName});

  final SellerDashboardMetrics metrics;
  final String shopName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final title = shopName.trim().isEmpty ? 'Shop của bạn' : shopName.trim();

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: AppSpacing.pagePaddingLg,
          children: [
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Theo dõi kho riêng và các đơn shop đang tự xử lý.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _MetricGrid(metrics: metrics),
            const SizedBox(height: AppSpacing.xl),
            const _QuickActions(),
            const SizedBox(height: AppSpacing.xl),
            _StockAlerts(metrics: metrics),
          ],
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});
  final SellerDashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 560;
        final cards = [
          _MetricCard(
            'Đơn chờ giao',
            '${metrics.awaitingDispatchCount}',
            Icons.inventory_2_outlined,
            cs.tertiary,
          ),
          _MetricCard(
            'Đang giao',
            '${metrics.shippingCount}',
            Icons.local_shipping_outlined,
            cs.primary,
          ),
          _MetricCard(
            'Sản phẩm hoạt động',
            '${metrics.activeProductCount}/${metrics.productCount}',
            Icons.storefront_outlined,
            cs.secondary,
          ),
          _MetricCard(
            'Giá trị đơn giao',
            formatCurrency(metrics.totalFulfillmentValue),
            Icons.payments_outlined,
            Colors.green,
          ),
        ];
        if (!twoColumns) {
          return Column(
            children: [
              for (final card in cards) ...[
                card,
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        }
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: cards
              .map(
                (card) => SizedBox(
                  width: (constraints.maxWidth - AppSpacing.sm) / 2,
                  child: card,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .6)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              borderRadius: AppRadii.borderSm,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thao tác nhanh',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => context.go(AppRoutes.fulfillments),
                icon: const Icon(Icons.local_shipping_outlined),
                label: const Text('Xử lý đơn giao'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.products),
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Quản lý kho'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StockAlerts extends StatelessWidget {
  const _StockAlerts({required this.metrics});
  final SellerDashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final alerts = [...metrics.outOfStockProducts, ...metrics.lowStockProducts];
    if (alerts.isEmpty) {
      return const EmptyState(
        icon: Icons.inventory_outlined,
        title: 'Kho hàng đang ổn định',
        message: 'Chưa có sản phẩm nào hết hàng hoặc sắp hết hàng.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cảnh báo tồn kho',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...alerts
            .take(6)
            .map(
              (product) => Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: ListTile(
                  leading: Icon(
                    product.stockQuantity <= 0
                        ? Icons.remove_shopping_cart_outlined
                        : Icons.warning_amber_outlined,
                  ),
                  title: Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    product.stockQuantity <= 0
                        ? 'Đã hết hàng'
                        : 'Chỉ còn ${product.stockQuantity} sản phẩm',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go(AppRoutes.productDetails(product.id)),
                ),
              ),
            ),
      ],
    );
  }
}
