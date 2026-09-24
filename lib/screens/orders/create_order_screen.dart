import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/billing.dart';
import '../../models/customer.dart';
import '../../providers/order_provider.dart';
import '../../services/fabric_calculator_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/billing_form.dart';
import '../../widgets/custom_text_field.dart';
import 'order_tracking_screen.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key, required this.customer});

  static const String routeName = '/orders/create';

  final Customer customer;

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FabricCalculatorService _fabricService = FabricCalculatorService();
  final TextEditingController _height = TextEditingController();
  final TextEditingController _width = TextEditingController();
  final TextEditingController _base = TextEditingController();
  final TextEditingController _laces = TextEditingController(text: '0');
  final TextEditingController _piping = TextEditingController(text: '0');
  final TextEditingController _other = TextEditingController(text: '0');
  final TextEditingController _urgentFee = TextEditingController(
    text: AppConstants.defaultUrgentDeliveryFee.toStringAsFixed(0),
  );

  late String _garment;
  bool _urgent = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _garment = AppConstants.garmentDesigns.first;
    _base.text =
        (AppConstants.defaultStitchingCosts[_garment] ?? 1500).toStringAsFixed(0);
    _height.text = widget.customer.measurement.length.toString();
    _width.text = widget.customer.measurement.chest.toString();
  }

  @override
  void dispose() {
    _height.dispose();
    _width.dispose();
    _base.dispose();
    _laces.dispose();
    _piping.dispose();
    _other.dispose();
    _urgentFee.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      final double meters = _fabricService.calculateFabric(
        designType: _garment,
        height: double.parse(_height.text.trim()),
        width: double.parse(_width.text.trim()),
      );
      final BillingDetails billing = BillingDetails(
        baseStitching: Validators.parseMoney(_base.text),
        laces: Validators.parseMoney(_laces.text),
        piping: Validators.parseMoney(_piping.text),
        otherStyling: Validators.parseMoney(_other.text),
        urgentDelivery: _urgent,
        urgentDeliveryFee: Validators.parseMoney(_urgentFee.text),
      );
      final created = await context.read<OrderProvider>().createOrder(
            customer: widget.customer,
            garmentType: _garment,
            measurements: widget.customer.measurement,
            fabricMeters: meters,
            fabricYards: _fabricService.toYards(meters),
            billing: billing,
          );
      if (!mounted) {
        return;
      }
      if (created == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to create order. Please try again.'),
          ),
        );
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Order Created Successfully'),
            content: Text('Order ID:\n${created.id}'),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('View Order'),
              ),
            ],
          );
        },
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(
        OrderTrackingScreen.routeName,
        arguments: created.id,
      );
    } on FabricCalculatorException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final OrderProvider orders = context.watch<OrderProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Create Order')),
      resizeToAvoidBottomInset: true,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Customer', style: Theme.of(context).textTheme.titleMedium),
            Text('${widget.customer.name} · ${widget.customer.phone}'),
            const SizedBox(height: 8),
            Text('Next Order ID: ${orders.previewNextOrderId()}'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _garment,
              decoration: const InputDecoration(labelText: 'Garment / design type'),
              items: [
                for (final String design in AppConstants.garmentDesigns)
                  DropdownMenuItem(value: design, child: Text(design)),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _garment = value;
                  _base.text = (AppConstants.defaultStitchingCosts[value] ?? 1500)
                      .toStringAsFixed(0);
                });
              },
            ),
            const SizedBox(height: 16),
            Text('Fabric estimate', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _height,
              label: 'Height (meters)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) =>
                  Validators.positiveNumber(value, fieldName: 'Height'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _width,
              label: 'Width (meters)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) =>
                  Validators.positiveNumber(value, fieldName: 'Width'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            _FabricPreview(
              service: _fabricService,
              design: _garment,
              heightText: _height.text,
              widthText: _width.text,
            ),
            const SizedBox(height: 16),
            Text('Billing', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            BillingForm(
              baseController: _base,
              lacesController: _laces,
              pipingController: _piping,
              otherController: _other,
              urgentFeeController: _urgentFee,
              urgentDelivery: _urgent,
              onUrgentChanged: (value) => setState(() => _urgent = value),
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Order'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FabricPreview extends StatelessWidget {
  const _FabricPreview({
    required this.service,
    required this.design,
    required this.heightText,
    required this.widthText,
  });

  final FabricCalculatorService service;
  final String design;
  final String heightText;
  final String widthText;

  @override
  Widget build(BuildContext context) {
    final double? height = Validators.parsePositive(heightText);
    final double? width = Validators.parsePositive(widthText);
    if (height == null || width == null) {
      return const Text('Enter valid height and width to estimate fabric.');
    }
    try {
      final double meters = service.calculateFabric(
        designType: design,
        height: height,
        width: width,
      );
      return Card(
        child: ListTile(
          title: const Text('Estimated Fabric Required'),
          subtitle: Text(
            '${Formatters.meters(meters)} · ${Formatters.yards(service.toYards(meters))}',
          ),
        ),
      );
    } on FabricCalculatorException catch (error) {
      return Text(error.message);
    }
  }
}
