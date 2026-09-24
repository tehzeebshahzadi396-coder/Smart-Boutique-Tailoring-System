import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../services/fabric_calculator_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';
import '../measurements/measurement_form_screen.dart';
import '../orders/create_order_screen.dart';

class FabricCalculatorScreen extends StatefulWidget {
  const FabricCalculatorScreen({
    super.key,
    this.embedded = false,
  });

  static const String routeName = '/calculator';

  final bool embedded;

  @override
  State<FabricCalculatorScreen> createState() => _FabricCalculatorScreenState();
}

class _FabricCalculatorScreenState extends State<FabricCalculatorScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _height = TextEditingController();
  final TextEditingController _width = TextEditingController();
  final FabricCalculatorService _service = FabricCalculatorService();

  String _design = AppConstants.garmentDesigns.first;
  double? _meters;
  double? _yards;
  String? _error;

  @override
  void dispose() {
    _height.dispose();
    _width.dispose();
    super.dispose();
  }

  void _autoEstimate() {
    final double? h = double.tryParse(_height.text.trim());
    final double? w = double.tryParse(_width.text.trim());
    if (h != null && w != null && h > 0 && w > 0) {
      try {
        final double meters = _service.calculateFabric(
          designType: _design,
          height: h,
          width: w,
        );
        setState(() {
          _meters = meters;
          _yards = _service.toYards(meters);
          _error = null;
        });
      } catch (_) {}
    }
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    try {
      final double meters = _service.calculateFabric(
        designType: _design,
        height: double.parse(_height.text.trim()),
        width: double.parse(_width.text.trim()),
      );
      setState(() {
        _meters = meters;
        _yards = _service.toYards(meters);
        _error = null;
      });
    } on FabricCalculatorException catch (error) {
      setState(() {
        _meters = null;
        _yards = null;
        _error = error.message;
      });
    }
  }

  Future<void> _selectCustomerAndCreateOrder() async {
    final CustomerProvider provider = context.read<CustomerProvider>();
    if (provider.customers.isEmpty) {
      final bool? proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('No customers found'),
          content: const Text(
            'Please add a customer before creating an order with this fabric estimate.',
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
      if (proceed == true && mounted) {
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Select Customer for Order',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: provider.customers.length,
                    itemBuilder: (context, index) {
                      final Customer customer = provider.customers[index];
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

    if (selected != null && mounted) {
      Navigator.of(context).pushNamed(
        CreateOrderScreen.routeName,
        arguments: selected,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: const Text('Fabric Calculator')),
      resizeToAvoidBottomInset: true,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _design,
              decoration: const InputDecoration(labelText: 'Garment design'),
              items: [
                for (final String design in AppConstants.garmentDesigns)
                  DropdownMenuItem(value: design, child: Text(design)),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _design = value);
                  _autoEstimate();
                }
              },
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _height,
              label: 'Height (meters)',
              hint: 'e.g. 1.50',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) =>
                  Validators.positiveNumber(value, fieldName: 'Height'),
              onChanged: (_) => _autoEstimate(),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _width,
              label: 'Width (meters)',
              hint: 'e.g. 2.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              validator: (value) =>
                  Validators.positiveNumber(value, fieldName: 'Width'),
              onChanged: (_) => _autoEstimate(),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _calculate,
              child: const Text('Calculate fabric'),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_meters != null && _yards != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated Fabric Required',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Formatters.meters(_meters!),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        Formatters.yards(_yards!),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppConstants.fabricEstimateDisclaimer,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: _selectCustomerAndCreateOrder,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Create Order with this Garment'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
