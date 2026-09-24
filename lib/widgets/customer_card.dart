import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../utils/formatters.dart';

class CustomerCard extends StatelessWidget {
  const CustomerCard({
    super.key,
    required this.customer,
    this.onTap,
  });

  final Customer customer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            customer.name.isEmpty ? '?' : customer.name[0].toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(customer.name),
        subtitle: Text('${customer.phone}\n${customer.id}'),
        isThreeLine: true,
        trailing: Text(
          Formatters.date(customer.updatedAt),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
