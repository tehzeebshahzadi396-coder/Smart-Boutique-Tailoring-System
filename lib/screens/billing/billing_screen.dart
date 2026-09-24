import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/billing.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../services/billing_calculator_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/billing_form.dart';
import 'invoice_screen.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key, this.orderId});

  static const String routeName = '/billing';

  final String? orderId;

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _base;
  late final TextEditingController _laces;
  late final TextEditingController _piping;
  late final TextEditingController _other;
  late final TextEditingController _urgentFee;
  bool _urgent = false;
  String? _activeOrderId;

  @override
  void initState() {
    super.initState();
    _activeOrderId = widget.orderId;
    _initFields();
  }

  void _initFields() {
    final Order? order = _activeOrderId == null
        ? null
        : context.read<OrderProvider>().findById(_activeOrderId!);
    final BillingDetails billing = order?.billing ??
        const BillingDetails(
          baseStitching: 1500,
          urgentDeliveryFee: AppConstants.defaultUrgentDeliveryFee,
        );
    _base = TextEditingController(text: billing.baseStitching.toStringAsFixed(0));
    _laces = TextEditingController(text: billing.laces.toStringAsFixed(0));
    _piping = TextEditingController(text: billing.piping.toStringAsFixed(0));
    _other = TextEditingController(text: billing.otherStyling.toStringAsFixed(0));
    _urgentFee =
        TextEditingController(text: billing.urgentDeliveryFee.toStringAsFixed(0));
    _urgent = billing.urgentDelivery;
  }

  void _loadOrderBilling(String? orderId) {
    setState(() {
      _activeOrderId = orderId;
      if (orderId != null) {
        final Order? order = context.read<OrderProvider>().findById(orderId);
        if (order != null) {
          _base.text = order.billing.baseStitching.toStringAsFixed(0);
          _laces.text = order.billing.laces.toStringAsFixed(0);
          _piping.text = order.billing.piping.toStringAsFixed(0);
          _other.text = order.billing.otherStyling.toStringAsFixed(0);
          _urgentFee.text = order.billing.urgentDeliveryFee.toStringAsFixed(0);
          _urgent = order.billing.urgentDelivery;
        }
      }
    });
  }

  @override
  void dispose() {
    _base.dispose();
    _laces.dispose();
    _piping.dispose();
    _other.dispose();
    _urgentFee.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final BillingDetails billing = BillingDetails(
      baseStitching: double.parse(_base.text.trim()),
      laces: double.parse(_laces.text.trim()),
      piping: double.parse(_piping.text.trim()),
      otherStyling: double.parse(_other.text.trim()),
      urgentDelivery: _urgent,
      urgentDeliveryFee: double.parse(_urgentFee.text.trim()),
    );

    if (_activeOrderId == null) {
      _showQuoteDialog(billing);
      return;
    }

    final bool success =
        await context.read<OrderProvider>().updateBilling(_activeOrderId!, billing);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Billing updated for order $_activeOrderId.'
              : 'Unable to update order. Please try again.',
        ),
      ),
    );
    if (success) {
      Navigator.of(context).pushNamed(
        InvoiceScreen.routeName,
        arguments: _activeOrderId,
      );
    }
  }

  void _showQuoteDialog(BillingDetails billing) {
    final BillingCalculatorService calc = BillingCalculatorService();
    final double subtotal = calc.subtotal(
      baseStitching: billing.baseStitching,
      laces: billing.laces,
      piping: billing.piping,
      otherStyling: billing.otherStyling,
    );
    final double total = calc.totalFrom(billing);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Estimated Bill Quote'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _quoteRow('Base Stitching', billing.baseStitching),
            _quoteRow('Laces', billing.laces),
            _quoteRow('Piping', billing.piping),
            _quoteRow('Other Styling', billing.otherStyling),
            const Divider(),
            _quoteRow('Subtotal', subtotal),
            _quoteRow(
              'Urgent Delivery Fee',
              billing.urgentDelivery ? billing.urgentDeliveryFee : 0,
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL BILL',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  Formatters.currency(total),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _quoteRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(Formatters.currency(amount)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final OrderProvider orderProvider = context.watch<OrderProvider>();
    final List<Order> orders = orderProvider.orders;

    return Scaffold(
      appBar: AppBar(title: const Text('Billing')),
      resizeToAvoidBottomInset: true,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (widget.orderId == null && orders.isNotEmpty) ...[
              DropdownButtonFormField<String?>(
                initialValue: _activeOrderId,
                decoration: const InputDecoration(
                  labelText: 'Select order to bill (optional)',
                  prefixIcon: Icon(Icons.receipt_outlined),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Standalone Quote (No Order)'),
                  ),
                  for (final Order order in orders)
                    DropdownMenuItem<String?>(
                      value: order.id,
                      child: Text(
                        '${order.id} · ${order.customerName} (${order.status.label})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: _loadOrderBilling,
              ),
              const SizedBox(height: 16),
            ] else if (_activeOrderId != null) ...[
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Editing billing for Order: $_activeOrderId',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
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
              onPressed: _save,
              child: Text(
                _activeOrderId == null
                    ? 'Review Quote'
                    : 'Save Billing & View Invoice',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
