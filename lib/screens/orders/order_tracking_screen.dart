import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/status_stepper.dart';
import '../billing/billing_screen.dart';
import '../billing/invoice_screen.dart';

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key, required this.orderId});

  static const String routeName = '/orders/track';

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final Order? order = context.watch<OrderProvider>().findById(orderId);
    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: const Center(child: Text('Order not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(order.id)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(order.customerName, style: Theme.of(context).textTheme.headlineSmall),
          Text(order.phone),
          Text(order.garmentType),
          const SizedBox(height: 8),
          Text('Order date: ${Formatters.date(order.orderDate)}'),
          Text('Expected delivery: ${Formatters.date(order.expectedDeliveryDate)}'),
          Text(
            'Fabric: ${Formatters.meters(order.fabricMeters)} · ${Formatters.yards(order.fabricYards)}',
          ),
          Text('Total: ${Formatters.currency(order.totalBill)}'),
          const SizedBox(height: 20),
          Text('Current status', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StatusStepper(current: order.status),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: order.status.canAdvance
                ? () => _advance(context, order)
                : null,
            child: Text(
              order.status.canAdvance
                  ? 'Mark as ${order.status.next!.label}'
                  : 'Delivered',
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: order.status == OrderStatus.pending
                ? null
                : () => _reset(context, order),
            child: const Text('Reset workflow to Pending'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pushNamed(
                BillingScreen.routeName,
                arguments: order.id,
              );
            },
            child: const Text('Edit billing'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pushNamed(
                InvoiceScreen.routeName,
                arguments: order.id,
              );
            },
            child: const Text('View invoice'),
          ),
        ],
      ),
    );
  }

  Future<void> _advance(BuildContext context, Order order) async {
    final bool success =
        await context.read<OrderProvider>().advanceStatus(order.id);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Status updated to ${context.read<OrderProvider>().findById(order.id)?.status.label}.'
              : 'Unable to update order. Please try again.',
        ),
      ),
    );
  }

  Future<void> _reset(BuildContext context, Order order) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset status?'),
          content: const Text(
            'This will move the order back to Pending. Use this only to correct a mistake.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    await context.read<OrderProvider>().resetStatus(order.id);
  }
}
