import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/order_model.dart';
import '../../data/models/seller_fulfillment.dart';
import '../../data/services/firestore_database.dart';
import '../../state/auth_controller.dart';

class SellerFulfillmentScreen extends StatelessWidget {
  const SellerFulfillmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthController>().currentUser!;
    final database = context.read<FirestoreDatabase>();
    return Scaffold(
      appBar: AppBar(title: const Text('Đơn cần giao')),
      body: StreamBuilder<List<SellerFulfillment>>(
        stream: database.watchSellerFulfillments(user.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final values = snapshot.data!;
          if (values.isEmpty) {
            return const Center(child: Text('Chưa có đơn nào cần shop giao.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: values.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final fulfillment = values[index];
              final next = fulfillment.status.nextStaffStatus;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đơn #${fulfillment.orderId}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${fulfillment.customerName} · ${fulfillment.phone}',
                      ),
                      Text(fulfillment.shippingAddress),
                      const SizedBox(height: 8),
                      Text(
                        '${fulfillment.items.length} sản phẩm · ${fulfillment.status.label}',
                      ),
                      if (next != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: () =>
                                database.updateSellerFulfillmentStatus(
                                  fulfillment: fulfillment,
                                  next: next,
                                ),
                            child: Text(
                              next.nextStaffActionLabel ?? next.label,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
