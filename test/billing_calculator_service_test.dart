import 'package:flutter_test/flutter_test.dart';

import 'package:smart_boutique/services/billing_calculator_service.dart';

void main() {
  final BillingCalculatorService calculator = BillingCalculatorService();

  test('base cost + styling + urgent fee = total', () {
    final double total = calculator.total(
      baseStitching: 1500,
      laces: 300,
      piping: 200,
      otherStyling: 0,
      urgentDelivery: true,
      urgentDeliveryFee: 500,
    );
    expect(total, 2500);
  });

  test('urgent fee is omitted when delivery is not urgent', () {
    final double total = calculator.total(
      baseStitching: 1500,
      laces: 300,
      piping: 200,
      otherStyling: 0,
      urgentDelivery: false,
      urgentDeliveryFee: 500,
    );
    expect(total, 2000);
  });
}
