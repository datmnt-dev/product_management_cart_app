import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/coupon_model.dart';
import '../../data/services/firestore_database.dart';

class CouponManagementScreen extends StatelessWidget {
  const CouponManagementScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mã giảm giá')),
    floatingActionButton: FloatingActionButton(
      onPressed: () => _editor(context),
      child: const Icon(Icons.add),
    ),
    body: StreamBuilder<List<Coupon>>(
      stream: context.read<FirestoreDatabase>().watchCoupons(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final coupons = snapshot.data!;
        if (coupons.isEmpty) {
          return const Center(child: Text('Chưa có mã giảm giá.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: coupons.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final coupon = coupons[index];
            final active = coupon.isAvailable(DateTime.now());
            return Card(
              child: ListTile(
                title: Text(coupon.code),
                subtitle: Text(
                  '${coupon.type.label}: ${coupon.type == CouponType.percent ? '${coupon.value.toStringAsFixed(0)}%' : formatCurrency(coupon.value)}\nĐã dùng ${coupon.usedCount}${coupon.usageLimit > 0 ? '/${coupon.usageLimit}' : ''} · Hết hạn ${formatDate(coupon.expiresAt)}',
                ),
                isThreeLine: true,
                trailing: Switch(
                  value: coupon.isActive,
                  onChanged: (value) => context
                      .read<FirestoreDatabase>()
                      .saveCoupon(coupon.copyWith(isActive: value)),
                ),
                leading: Icon(
                  active ? Icons.local_offer_outlined : Icons.block_outlined,
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

Future<void> _editor(BuildContext context) async {
  final code = TextEditingController();
  final value = TextEditingController();
  final min = TextEditingController(text: '0');
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Tạo mã giảm giá'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: code,
            decoration: const InputDecoration(labelText: 'Mã'),
          ),
          TextField(
            controller: value,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '% giảm'),
          ),
          TextField(
            controller: min,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Đơn tối thiểu'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () async {
            final amount = double.tryParse(value.text) ?? 0;
            if (Coupon.normalizeCode(code.text).isEmpty || amount <= 0) return;
            await dialogContext.read<FirestoreDatabase>().saveCoupon(
              Coupon(
                code: code.text,
                type: CouponType.percent,
                value: amount,
                minOrderAmount: double.tryParse(min.text) ?? 0,
                maxDiscountAmount: 0,
                startsAt: DateTime.now(),
                expiresAt: DateTime.now().add(const Duration(days: 30)),
              ),
            );
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          },
          child: const Text('Tạo'),
        ),
      ],
    ),
  );
  code.dispose();
  value.dispose();
  min.dispose();
}
