import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/customer_card.dart';
import '../../widgets/empty_state.dart';
import 'customer_detail_screen.dart';
import 'measurement_form_screen.dart';

class CustomerSearchScreen extends StatelessWidget {
  const CustomerSearchScreen({
    super.key,
    this.embedded = false,
  });

  static const String routeName = '/customers';

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final CustomerProvider provider = context.watch<CustomerProvider>();
    final Widget content;
    if (provider.isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (provider.customers.isEmpty) {
      content = EmptyState(
        title: 'No customers yet',
        message:
            'Add your first customer to start managing measurements.',
        actionLabel: 'Add Customer',
        icon: Icons.person_add_alt,
        onAction: () {
          Navigator.of(context).pushNamed(MeasurementFormScreen.routeName);
        },
      );
    } else if (provider.filteredCustomers.isEmpty) {
      content = const EmptyState(
        title: 'No customer found',
        message: 'Try a different name or phone number.',
        icon: Icons.search_off,
      );
    } else {
      content = ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
        itemCount: provider.filteredCustomers.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final Customer customer = provider.filteredCustomers[index];
          return CustomerCard(
            customer: customer,
            onTap: () {
              Navigator.of(context).pushNamed(
                CustomerDetailScreen.routeName,
                arguments: customer.id,
              );
            },
          );
        },
      );
    }

    final Widget body = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            onChanged: provider.setSearchQuery,
            decoration: const InputDecoration(
              hintText: 'Search customer...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        Expanded(child: content),
      ],
    );

    if (embedded) {
      return Scaffold(
        resizeToAvoidBottomInset: true,
        body: body,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).pushNamed(MeasurementFormScreen.routeName);
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Customer'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      resizeToAvoidBottomInset: true,
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed(MeasurementFormScreen.routeName);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Customer'),
      ),
    );
  }
}
