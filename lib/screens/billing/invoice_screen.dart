import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../services/billing_calculator_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/formatters.dart';

/// Modular invoice view. Layout is isolated so PDF/print can wrap this later.
class InvoiceScreen extends StatelessWidget {
  const InvoiceScreen({super.key, required this.orderId});

  static const String routeName = '/invoice';

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final Order? order = context.watch<OrderProvider>().findById(orderId);
    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice')),
        body: const Center(child: Text('Invoice not found.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          InvoiceView(order: order),
        ],
      ),
    );
  }
}

class InvoiceView extends StatelessWidget {
  const InvoiceView({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final BillingCalculatorService calculator = BillingCalculatorService();
    final double urgent = calculator.urgentFee(
      urgentDelivery: order.billing.urgentDelivery,
      fee: order.billing.urgentDeliveryFee,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppConstants.appName.toUpperCase(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 16),
            Text('Order ID: ${order.id}'),
            const SizedBox(height: 12),
            const Text('Customer:'),
            Text(order.customerName, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('Phone:'),
            Text(order.phone),
            const SizedBox(height: 8),
            const Text('Garment:'),
            Text(order.garmentType),
            const Divider(height: 32),
            _row('Base Stitching', order.billing.baseStitching),
            _row('Laces', order.billing.laces),
            _row('Piping', order.billing.piping),
            _row('Other Styling', order.billing.otherStyling),
            _row('Urgent Delivery', urgent),
            const Divider(height: 32),
            Row(
              children: [
                const Expanded(
                  child: Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Text(
                  Formatters.currency(order.totalBill),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Status:\n${order.status.label}'),
            const SizedBox(height: 24),
            const Text('Thank you!', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invoice prepared for export / printing.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Print / Share'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(Formatters.currency(amount)),
        ],
      ),
    );
  }
}
