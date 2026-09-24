import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../models/measurement.dart';
import '../../providers/customer_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';

class MeasurementFormScreen extends StatefulWidget {
  const MeasurementFormScreen({super.key, this.customerId});

  static const String routeName = '/measurements/form';

  final String? customerId;

  @override
  State<MeasurementFormScreen> createState() => _MeasurementFormScreenState();
}

class _MeasurementFormScreenState extends State<MeasurementFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _teera = TextEditingController();
  final TextEditingController _chest = TextEditingController();
  final TextEditingController _waist = TextEditingController();
  final TextEditingController _armhole = TextEditingController();
  final TextEditingController _length = TextEditingController();

  Customer? _existing;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.customerId != null) {
      _existing = context.read<CustomerProvider>().findById(widget.customerId!);
      if (_existing != null) {
        _name.text = _existing!.name;
        _phone.text = _existing!.phone;
        _teera.text = _existing!.measurement.teera.toString();
        _chest.text = _existing!.measurement.chest.toString();
        _waist.text = _existing!.measurement.waist.toString();
        _armhole.text = _existing!.measurement.armhole.toString();
        _length.text = _existing!.measurement.length.toString();
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _teera.dispose();
    _chest.dispose();
    _waist.dispose();
    _armhole.dispose();
    _length.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    final Measurement measurement = Measurement(
      teera: double.parse(_teera.text.trim()),
      chest: double.parse(_chest.text.trim()),
      waist: double.parse(_waist.text.trim()),
      armhole: double.parse(_armhole.text.trim()),
      length: double.parse(_length.text.trim()),
    );
    final CustomerProvider provider = context.read<CustomerProvider>();
    final bool success;
    if (_existing == null) {
      success = await provider.addCustomer(
        name: _name.text,
        phone: _phone.text,
        measurement: measurement,
      );
    } else {
      success = await provider.updateCustomer(
        _existing!.copyWith(
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          measurement: measurement,
        ),
      );
    }
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _existing == null
                ? 'Customer profile saved.'
                : 'Measurements updated.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Unable to save customer. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? 'Add Customer' : 'Edit Measurements'),
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              CustomTextField(
                controller: _name,
                label: 'Customer name',
                prefixIcon: Icons.person_outline,
                validator: Validators.requiredName,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _phone,
                label: 'Phone number',
                hint: '03XX-XXXXXXX',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: Validators.requiredPhone,
              ),
              const SizedBox(height: 20),
              Text(
                'Tailoring measurements',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _teera,
                label: 'Teera (inches)',
                hint: 'e.g. 14.5',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) =>
                    Validators.positiveNumber(value, fieldName: 'Teera'),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _chest,
                label: 'Chest (inches)',
                hint: 'e.g. 36.0',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) =>
                    Validators.positiveNumber(value, fieldName: 'Chest'),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _waist,
                label: 'Waist (inches)',
                hint: 'e.g. 30.0',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) =>
                    Validators.positiveNumber(value, fieldName: 'Waist'),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _armhole,
                label: 'Armhole (inches)',
                hint: 'e.g. 16.0',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) =>
                    Validators.positiveNumber(value, fieldName: 'Armhole'),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _length,
                label: 'Length (inches)',
                hint: 'e.g. 40.0',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                validator: (value) =>
                    Validators.positiveNumber(value, fieldName: 'Length'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
