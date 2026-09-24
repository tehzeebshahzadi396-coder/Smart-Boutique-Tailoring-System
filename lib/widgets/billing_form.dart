import 'package:flutter/material.dart';

import '../models/billing.dart';
import '../services/billing_calculator_service.dart';
import '../utils/app_constants.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import 'custom_text_field.dart';

class BillingForm extends StatelessWidget {
  const BillingForm({
    super.key,
    required this.baseController,
    required this.lacesController,
    required this.pipingController,
    required this.otherController,
    required this.urgentFeeController,
    required this.urgentDelivery,
    required this.onUrgentChanged,
    this.onChanged,
  });

  final TextEditingController baseController;
  final TextEditingController lacesController;
  final TextEditingController pipingController;
  final TextEditingController otherController;
  final TextEditingController urgentFeeController;
  final bool urgentDelivery;
  final ValueChanged<bool> onUrgentChanged;
  final VoidCallback? onChanged;

  BillingDetails toBilling() {
    return BillingDetails(
      baseStitching: Validators.parseMoney(baseController.text),
      laces: Validators.parseMoney(lacesController.text),
      piping: Validators.parseMoney(pipingController.text),
      otherStyling: Validators.parseMoney(otherController.text),
      urgentDelivery: urgentDelivery,
      urgentDeliveryFee: Validators.parseMoney(urgentFeeController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final BillingCalculatorService calculator = BillingCalculatorService();
    final BillingDetails billing = toBilling();
    final double subtotal = calculator.subtotal(
      baseStitching: billing.baseStitching,
      laces: billing.laces,
      piping: billing.piping,
      otherStyling: billing.otherStyling,
    );
    final double total = calculator.totalFrom(billing);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomTextField(
          controller: baseController,
          label: 'Base Stitching',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) =>
              Validators.nonNegativeMoney(value, fieldName: 'base stitching'),
          prefixIcon: Icons.payments_outlined,
          onChanged: (_) => onChanged?.call(),
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: lacesController,
          label: 'Laces',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) =>
              Validators.nonNegativeMoney(value, fieldName: 'laces'),
          onChanged: (_) => onChanged?.call(),
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: pipingController,
          label: 'Piping',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) =>
              Validators.nonNegativeMoney(value, fieldName: 'piping'),
          onChanged: (_) => onChanged?.call(),
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: otherController,
          label: 'Other Styling',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) =>
              Validators.nonNegativeMoney(value, fieldName: 'other styling'),
          onChanged: (_) => onChanged?.call(),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Urgent Delivery'),
          subtitle: Text(
            'Adds ${Formatters.currency(Validators.parseMoney(urgentFeeController.text))} and faster delivery',
          ),
          value: urgentDelivery,
          onChanged: onUrgentChanged,
        ),
        if (urgentDelivery) ...[
          CustomTextField(
            controller: urgentFeeController,
            label: 'Urgent Delivery Fee',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) =>
                Validators.nonNegativeMoney(value, fieldName: 'urgent fee'),
            onChanged: (_) => onChanged?.call(),
          ),
          const SizedBox(height: 12),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _line(context, 'Base Stitching', billing.baseStitching),
                _line(context, 'Laces', billing.laces),
                _line(context, 'Piping', billing.piping),
                _line(context, 'Other Styling', billing.otherStyling),
                const Divider(),
                _line(context, 'Subtotal', subtotal),
                _line(
                  context,
                  'Urgent Delivery',
                  calculator.urgentFee(
                    urgentDelivery: billing.urgentDelivery,
                    fee: billing.urgentDeliveryFee,
                  ),
                ),
                const Divider(),
                Text(
                  'Total Bill',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  Formatters.currency(total),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  AppConstants.currencyCode,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _line(BuildContext context, String label, double amount) {
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
