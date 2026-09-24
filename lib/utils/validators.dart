/// Shared form validators for customer, measurement, and billing fields.
class Validators {
  Validators._();

  static String? requiredName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter customer name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? requiredPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter phone number';
    }
    final String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10) {
      return 'Enter a valid phone number (at least 10 digits)';
    }
    return null;
  }

  static String? positiveNumber(String? value, {required String fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    final double? parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Invalid measurement value. Please enter a valid number.';
    }
    if (parsed <= 0) {
      return '$fieldName must be a positive number';
    }
    return null;
  }

  static String? nonNegativeMoney(String? value, {required String fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    final double? parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Please enter a valid amount for $fieldName';
    }
    if (parsed < 0) {
      return '$fieldName cannot be negative';
    }
    return null;
  }

  static double? parsePositive(String? value) {
    if (value == null) {
      return null;
    }
    final double? parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  static double parseMoney(String? value) {
    return double.tryParse(value?.trim() ?? '') ?? 0;
  }
}
