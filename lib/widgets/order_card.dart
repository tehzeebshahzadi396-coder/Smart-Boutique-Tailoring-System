import 'package:flutter/material.dart';

import '../models/order.dart';
import '../utils/formatters.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
  });

  final Order order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        title: Text(
          order.id,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.customerName),
              Text(order.garmentType),
              const SizedBox(height: 4),
              Text('Status: ${order.status.label}'),
            ],
          ),
        ),
        isThreeLine: true,
        trailing: Text(
          Formatters.currency(order.totalBill),
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
    );
  }
}
