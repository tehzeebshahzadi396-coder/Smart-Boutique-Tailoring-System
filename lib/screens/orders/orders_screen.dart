import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_boutique/services/whatsapp_service.dart';

import '../../models/customer.dart';
import '../../models/order.dart';
import '../../providers/customer_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/order_card.dart';
import '../measurements/measurement_form_screen.dart';
import 'create_order_screen.dart';
import 'order_tracking_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key, this.embedded = false});

  static const String routeName = '/orders';

  final bool embedded;

  Future<void> _showNewOrderPicker(BuildContext context) async {
    final CustomerProvider customerProvider = context.read<CustomerProvider>();
    if (customerProvider.customers.isEmpty) {
      final bool? proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('No customers found'),
          content: const Text(
            'To create an order, please add a customer with measurements first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add Customer'),
            ),
          ],
        ),
      );
      if (proceed == true && context.mounted) {
        Navigator.of(context).pushNamed(MeasurementFormScreen.routeName);
      }
      return;
    }

    final Customer? selected = await showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Text(
                    'Select Customer for Order',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: customerProvider.customers.length,
                    itemBuilder: (context, index) {
                      final Customer customer =
                          customerProvider.customers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            customer.name.isEmpty ? '?' : customer.name[0],
                          ),
                        ),
                        title: Text(customer.name),
                        subtitle: Text('${customer.phone} · ${customer.id}'),
                        onTap: () => Navigator.pop(ctx, customer),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected != null && context.mounted) {
      Navigator.of(context)
          .pushNamed(CreateOrderScreen.routeName, arguments: selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final OrderProvider provider = context.watch<OrderProvider>();
    final Widget body = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            onChanged: provider.setSearchQuery,
            decoration: const InputDecoration(
              hintText: 'Search by order ID, name, or phone',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                selected: provider.statusFilter == null,
                onSelected: () => provider.setStatusFilter(null),
              ),
              for (final OrderStatus status in OrderStatus.values)
                _FilterChip(
                  label: status.label,
                  selected: provider.statusFilter == status,
                  onSelected: () => provider.setStatusFilter(status),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _OrdersBody(provider: provider)),
      ],
    );

    final fab = FloatingActionButton.extended(
      onPressed: () => _showNewOrderPicker(context),
      icon: const Icon(Icons.add),
      label: const Text('New Order'),
    );

    if (embedded) {
      return Scaffold(
        resizeToAvoidBottomInset: true,
        body: body,
        floatingActionButton: fab,
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      resizeToAvoidBottomInset: true,
      body: body,
      floatingActionButton: fab,
    );
  }
}

class _OrdersBody extends StatelessWidget {
  const _OrdersBody({required this.provider});

  final OrderProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null && provider.orders.isEmpty) {
      return const EmptyState(
        title: 'Unable to load orders.',
        message: 'Please try again after restarting the app.',
        icon: Icons.error_outline,
      );
    }
    if (provider.orders.isEmpty) {
      return const EmptyState(
        title: 'No orders found',
        message: 'Create a new order from a customer profile.',
        icon: Icons.receipt_long_outlined,
      );
    }
    if (provider.filteredOrders.isEmpty) {
      return const EmptyState(
        title: 'No orders found',
        message: 'No orders match the current search or filter.',
        icon: Icons.filter_alt_off,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: provider.filteredOrders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final Order order = provider.filteredOrders[index];
        return Column(
          children: [
            OrderCard(
              order: order,
              onTap: () {
                Navigator.of(
                  context,
                ).pushNamed(OrderTrackingScreen.routeName, arguments: order.id);
              },
            ),
            const SizedBox(height: 6),
            // Image me bataya gaya WhatsApp Button[cite: 1]
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.chat),
                label: const Text('Send Bill via WhatsApp'),
                onPressed: () {
                  WhatsAppService.sendMessage(
                    phoneNumber: order.phone, // Apne model ke field name ke hisab se pass karein (e.g. order.customerPhone ya order.phone)
                    message:
                        "Hello! Aapka order #${order.id} receive ho gaya hai.",
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}
