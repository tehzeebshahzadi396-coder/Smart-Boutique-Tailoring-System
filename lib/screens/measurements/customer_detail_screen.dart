import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../utils/formatters.dart';
import '../orders/create_order_screen.dart';
import 'measurement_form_screen.dart';

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  static const String routeName = '/customers/detail';

  final String customerId;

  @override
  Widget build(BuildContext context) {
    final Customer? customer =
        context.watch<CustomerProvider>().findById(customerId);
    if (customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer')),
        body: const Center(child: Text('Customer profile not found.')),
      );
    }

    final measurement = customer.measurement;
    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        actions: [
          IconButton(
            tooltip: 'Edit measurements',
            onPressed: () {
              Navigator.of(context).pushNamed(
                MeasurementFormScreen.routeName,
                arguments: customer.id,
              );
            },
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete profile',
            onPressed: () => _confirmDelete(context, customer),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.name,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('ID: ${customer.id}'),
                  Text('Phone: ${customer.phone}'),
                  Text('Created: ${Formatters.date(customer.createdAt)}'),
                  Text('Last updated: ${Formatters.dateTime(customer.updatedAt)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Measurements', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _row('Teera', measurement.teera),
                _row('Chest', measurement.chest),
                _row('Waist', measurement.waist),
                _row('Armhole', measurement.armhole),
                _row('Length', measurement.length),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(
                CreateOrderScreen.routeName,
                arguments: customer.id,
              );
            },
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Create Order'),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, double value) {
    return ListTile(
      title: Text(label),
      trailing: Text(
        '${value.toStringAsFixed(1)} in',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Customer customer) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete profile?'),
          content: Text(
            'This will remove ${customer.name} and their measurements from this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final bool success =
        await context.read<CustomerProvider>().deleteCustomer(customer.id);
    if (!context.mounted) {
      return;
    }
    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete customer. Please try again.')),
      );
    }
  }
}
