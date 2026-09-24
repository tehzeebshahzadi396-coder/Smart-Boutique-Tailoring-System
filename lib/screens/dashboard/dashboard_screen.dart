import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../providers/customer_provider.dart';
import '../../providers/order_provider.dart';
import '../../utils/app_constants.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/order_card.dart';
import '../billing/billing_screen.dart';
import '../measurements/measurement_form_screen.dart';
import '../orders/order_tracking_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    this.onOpenTab,
  });

  final ValueChanged<int>? onOpenTab;

  @override
  Widget build(BuildContext context) {
    final CustomerProvider customers = context.watch<CustomerProvider>();
    final OrderProvider orders = context.watch<OrderProvider>();

    if (customers.isLoading || orders.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool wide = constraints.maxWidth >= 700;
        final int columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 600
                ? 2
                : 2;
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppConstants.appFullName,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Today's Overview",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: wide ? 1.6 : 1.25,
                ),
                delegate: SliverChildListDelegate([
                  DashboardCard(
                    title: 'Customers',
                    value: '${customers.customers.length}',
                    icon: Icons.people_alt_outlined,
                    onTap: () => onOpenTab?.call(1),
                  ),
                  DashboardCard(
                    title: 'Active Orders',
                    value: '${orders.customerFacingActiveCount}',
                    icon: Icons.inventory_2_outlined,
                    onTap: () => onOpenTab?.call(3),
                  ),
                  DashboardCard(
                    title: 'Ready Orders',
                    value: '${orders.readyOrders}',
                    icon: Icons.checkroom_outlined,
                    onTap: () => onOpenTab?.call(3),
                  ),
                  DashboardCard(
                    title: 'Delivered',
                    value: '${orders.deliveredOrders}',
                    icon: Icons.local_shipping_outlined,
                    onTap: () => onOpenTab?.call(3),
                  ),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.person_add_alt),
                      label: const Text('Customers'),
                      onPressed: () => onOpenTab?.call(1),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.straighten),
                      label: const Text('Measurements'),
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          MeasurementFormScreen.routeName,
                        );
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.calculate_outlined),
                      label: const Text('Fabric Calculator'),
                      onPressed: () => onOpenTab?.call(2),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.receipt_long_outlined),
                      label: const Text('Orders'),
                      onPressed: () => onOpenTab?.call(3),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.payments_outlined),
                      label: const Text('Billing'),
                      onPressed: () {
                        Navigator.of(context).pushNamed(BillingScreen.routeName);
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Recent Orders',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            if (orders.recentOrders.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  title: 'No orders found',
                  message: 'Create a new order from a customer profile.',
                  icon: Icons.receipt_long_outlined,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.builder(
                  itemCount: orders.recentOrders.length,
                  itemBuilder: (context, index) {
                    final Order order = orders.recentOrders[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: OrderCard(
                        order: order,
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            OrderTrackingScreen.routeName,
                            arguments: order.id,
                          );
                        },
                      ),
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
