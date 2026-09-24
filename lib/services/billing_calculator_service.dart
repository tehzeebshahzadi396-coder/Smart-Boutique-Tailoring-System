import '../models/billing.dart';

class BillingCalculatorService {
  double subtotal({
    required double baseStitching,
    required double laces,
    required double piping,
    required double otherStyling,
  }) {
    return baseStitching + laces + piping + otherStyling;
  }

  double urgentFee({required bool urgentDelivery, required double fee}) {
    return urgentDelivery ? fee : 0;
  }

  double total({
    required double baseStitching,
    required double laces,
    required double piping,
    required double otherStyling,
    required bool urgentDelivery,
    required double urgentDeliveryFee,
  }) {
    return subtotal(
          baseStitching: baseStitching,
          laces: laces,
          piping: piping,
          otherStyling: otherStyling,
        ) +
        urgentFee(urgentDelivery: urgentDelivery, fee: urgentDeliveryFee);
  }

  double totalFrom(BillingDetails billing) {
    return total(
      baseStitching: billing.baseStitching,
      laces: billing.laces,
      piping: billing.piping,
      otherStyling: billing.otherStyling,
      urgentDelivery: billing.urgentDelivery,
      urgentDeliveryFee: billing.urgentDeliveryFee,
    );
  }
}
