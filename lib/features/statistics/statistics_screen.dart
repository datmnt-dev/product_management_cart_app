import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/order_model.dart';
import '../../shared/widgets/empty_state.dart';
import '../../state/order_controller.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo & Thống kê'),
        actions: [
          IconButton(
            tooltip: 'Sản phẩm',
            onPressed: () => context.go(AppRoutes.products),
            icon: const Icon(Icons.storefront_outlined),
          ),
        ],
      ),
      body: Consumer<OrderController>(builder: (context, orders, _) {
        if (orders.orders.isEmpty) {
          return EmptyState(
            icon: Icons.analytics_outlined,
            title: 'Chưa có dữ liệu bán hàng',
            message: 'Khi người dùng đặt hàng thành công, doanh thu và thống kê sẽ được tổng hợp ở đây.',
            action: FilledButton.icon(
              onPressed: () => context.go(AppRoutes.products),
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Xem sản phẩm mua bán'),
            ),
          );
        }

        final filteredOrders = orders.filteredOrders;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
          children: [
            // ── Main Revenue Card ──
            _RevenueDashboardCard(controller: orders),
            const SizedBox(height: 24),

            // ── Grid metrics panel ──
            Row(
              children: [
                Expanded(
                  child: _MiniMetricCard(
                    title: 'Đơn hàng lọc',
                    value: '${filteredOrders.length} đơn',
                    icon: Icons.receipt_long_outlined,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MiniMetricCard(
                    title: 'Đơn hàng/Ngày',
                    value: _calcOrdersPerDay(filteredOrders),
                    icon: Icons.calendar_today_outlined,
                    color: cs.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MiniMetricCard(
                    title: 'Giá trị trung bình',
                    value: filteredOrders.isEmpty
                        ? '0đ'
                        : formatCurrency(orders.filteredRevenue / filteredOrders.length),
                    icon: Icons.payments_outlined,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MiniMetricCard(
                    title: 'Sản phẩm đã bán',
                    value: '${_calcTotalItemsSold(filteredOrders)} món',
                    icon: Icons.shopping_basket_outlined,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Interactive Sales Trend Chart ──
            Text(
              'Xu hướng doanh số',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -.3),
            ),
            const SizedBox(height: 6),
            Text(
              'Biểu đồ thống kê doanh số trực quan dựa trên bộ lọc thời gian',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            _SalesBarChart(orders: orders.orders, filter: orders.filter),
            const SizedBox(height: 28),

            // ── Best Selling Products ──
            Text(
              'Sản phẩm bán chạy nhất',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -.3),
            ),
            const SizedBox(height: 6),
            Text(
              'Top các sản phẩm có số lượng bán ra nhiều nhất',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            _BestSellersList(orders: filteredOrders),
            const SizedBox(height: 28),

            // ── Time filter buttons ──
            Text(
              'Bộ lọc thời gian báo cáo',
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<RevenueFilter>(
                selected: {orders.filter},
                onSelectionChanged: (s) => orders.setFilter(s.first),
                segments: const [
                  ButtonSegment(value: RevenueFilter.all, icon: Icon(Icons.grid_view, size: 16), label: Text('Tất cả')),
                  ButtonSegment(value: RevenueFilter.day, icon: Icon(Icons.today, size: 16), label: Text('Hôm nay')),
                  ButtonSegment(value: RevenueFilter.month, icon: Icon(Icons.calendar_month, size: 16), label: Text('Tháng')),
                  ButtonSegment(value: RevenueFilter.year, icon: Icon(Icons.calendar_today, size: 16), label: Text('Năm')),
                ],
              ),
            ),
            const SizedBox(height: 28),

            Row(
              children: [
                Text(
                  'Danh sách đơn hàng',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${filteredOrders.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (filteredOrders.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: EmptyState(
                  icon: Icons.filter_alt_off_outlined,
                  title: 'Không tìm thấy hóa đơn',
                  message: 'Không có giao dịch nào khớp với bộ lọc thời gian đang chọn.',
                ),
              )
            else
              ...filteredOrders.map((o) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OrderCard(order: o),
              )),
          ],
        );
      }),
    );
  }

  int _calcTotalItemsSold(List<OrderModel> orders) {
    return orders.fold<int>(0, (sum, o) => sum + o.totalQuantity);
  }

  String _calcOrdersPerDay(List<OrderModel> orders) {
    if (orders.isEmpty) return '0';
    final dates = orders.map((o) => DateUtils.dateOnly(o.createdAt)).toSet();
    final days = dates.isEmpty ? 1 : dates.length;
    return (orders.length / days).toStringAsFixed(1);
  }
}

class _RevenueDashboardCard extends StatelessWidget {
  const _RevenueDashboardCard({required this.controller});
  final OrderController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary,
            cs.primary.withValues(alpha: .85),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: .18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: Colors.white.withValues(alpha: .75), size: 18),
              const SizedBox(width: 8),
              Text(
                'DOANH THU THEO BỘ LỌC',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .8),
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: .5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatCurrency(controller.filteredRevenue),
            style: tt.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TẤT CẢ THỜI GIAN',
                    style: TextStyle(color: Colors.white.withValues(alpha: .6), fontSize: 9, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    formatCurrency(controller.totalRevenue),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Tổng ${controller.orders.length} đơn hàng',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetricCard extends StatelessWidget {
  const _MiniMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

// ── Custom Bar Chart ──
class _BarData {
  _BarData({required this.label, required this.value});
  final String label;
  final double value;
}

class _SalesBarChart extends StatelessWidget {
  const _SalesBarChart({required this.orders, required this.filter});
  final List<OrderModel> orders;
  final RevenueFilter filter;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();

    List<_BarData> dataPoints = [];
    if (filter == RevenueFilter.all || filter == RevenueFilter.year) {
      // Group by Month (Last 6 Months)
      dataPoints = List.generate(6, (index) {
        final date = DateTime(now.year, now.month - (5 - index), 1);
        final monthOrders = orders.where((o) => o.createdAt.year == date.year && o.createdAt.month == date.month);
        final total = monthOrders.fold<double>(0, (sum, o) => sum + o.totalAmount);
        return _BarData(label: 'T${date.month}', value: total);
      });
    } else {
      // Group by Day (Last 7 Days)
      dataPoints = List.generate(7, (index) {
        final date = now.subtract(Duration(days: 6 - index));
        final dayOrders = orders.where((o) =>
            o.createdAt.year == date.year &&
            o.createdAt.month == date.month &&
            o.createdAt.day == date.day);
        final total = dayOrders.fold<double>(0, (sum, o) => sum + o.totalAmount);
        return _BarData(label: '${date.day}/${date.month}', value: total);
      });
    }

    final maxVal = dataPoints.fold<double>(0, (max, p) => p.value > max ? p.value : max);

    return Container(
      height: 190,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .45)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: dataPoints.map((dp) {
          final ratio = maxVal == 0 ? 0.0 : (dp.value / maxVal);
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Amount tooltip label above bar
                Text(
                  _formatShortValue(dp.value),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: dp.value > 0 ? cs.primary : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 6),
                // Visual Bar
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(dp.value),
                    tween: Tween(begin: 0.0, end: ratio.clamp(0.06, 1.0)),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedRatio, child) {
                      return FractionallySizedBox(
                        heightFactor: animatedRatio,
                        child: child,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            cs.primary.withValues(alpha: .5),
                            cs.primary,
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Time category label below bar
                Text(
                  dp.label,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatShortValue(double val) {
    if (val == 0) return '0đ';
    if (val >= 1000000) return '${(val / 1000000).toStringAsFixed(1)}M';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(0)}k';
    return '${val.toStringAsFixed(0)}đ';
  }
}

// ── Best Selling Products Listing ──
class _ProductSale {
  _ProductSale({required this.name, required this.quantity});
  final String name;
  final int quantity;
}

class _BestSellersList extends StatelessWidget {
  const _BestSellersList({required this.orders});
  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Aggregate products sold
    final counts = <String, int>{};
    for (final order in orders) {
      for (final item in order.items) {
        counts[item.name] = (counts[item.name] ?? 0) + item.quantity;
      }
    }

    final sortedList = counts.entries
        .map((e) => _ProductSale(name: e.key, quantity: e.value))
        .toList()
      ..sort((a, b) => b.quantity.compareTo(a.quantity));

    final bestSellers = sortedList.take(4).toList();

    if (bestSellers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: Text(
          'Không có dữ liệu mặt hàng',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      );
    }

    final maxSales = bestSellers.first.quantity;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .45)),
      ),
      child: Column(
        children: bestSellers.map((item) {
          final percent = maxSales == 0 ? 0.0 : (item.quantity / maxSales);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.quantity} cái',
                      style: TextStyle(fontWeight: FontWeight.w900, color: cs.primary, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 6,
                    backgroundColor: cs.primary.withValues(alpha: .08),
                    valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final shortId = order.id.split('-').last.toUpperCase();

    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: CircleAvatar(
          backgroundColor: cs.secondaryContainer,
          foregroundColor: cs.onSecondaryContainer,
          child: const Icon(Icons.receipt_long, size: 20),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Đơn hàng #$shortId',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            ),
            Text(
              formatCurrency(order.totalAmount),
              style: TextStyle(fontWeight: FontWeight.w900, color: cs.primary, fontSize: 13),
            ),
          ],
        ),
        subtitle: Text(
          'Khách hàng: ${order.userEmail}\n${order.totalQuantity} sản phẩm · ${formatDate(order.createdAt)}',
          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, height: 1.4, fontWeight: FontWeight.w600),
        ),
        children: [
          const Divider(height: 20),
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
                Text(
                  '${item.quantity} × ${formatCurrency(item.unitPrice)}',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
