import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/customer_provider.dart';
import '../../providers/order_provider.dart';
import '../calculator/fabric_calculator_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../measurements/customer_search_screen.dart';
import '../orders/orders_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  static const String routeName = '/';

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardScreen(onOpenTab: (index) => setState(() => _index = index)),
      const CustomerSearchScreen(embedded: true),
      const FabricCalculatorScreen(embedded: true),
      const OrdersScreen(embedded: true),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleFor(_index)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'App options',
            onSelected: (value) async {
              if (value == 'demo') {
                final customerProvider = context.read<CustomerProvider>();
                final orderProvider = context.read<OrderProvider>();
                await customerProvider.seedSampleCustomers();
                await orderProvider.seedSampleOrders(customerProvider.customers);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Demo sample data loaded successfully!'),
                    ),
                  );
                }
              } else if (value == 'clear') {
                final bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear all data?'),
                    content: const Text(
                      'This will remove all customers and orders saved in local storage.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  final customerProvider = context.read<CustomerProvider>();
                  final orderProvider = context.read<OrderProvider>();
                  await customerProvider.clearAll();
                  await orderProvider.clearAll();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All local data cleared.')),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'demo',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 20),
                    SizedBox(width: 8),
                    Text('Load Demo Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Clear All Data'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: 'Calculator',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
        ],
      ),
    );
  }

  String _titleFor(int index) {
    switch (index) {
      case 1:
        return 'Customers';
      case 2:
        return 'Fabric Calculator';
      case 3:
        return 'Orders';
      default:
        return 'Dashboard';
    }
  }
}
