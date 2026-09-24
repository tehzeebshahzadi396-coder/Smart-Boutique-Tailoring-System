class BillingDetails {
  final double baseStitching;
  final double laces;
  final double piping;
  final double otherStyling;
  final bool urgentDelivery;
  final double urgentDeliveryFee;

  const BillingDetails({
    required this.baseStitching,
    this.laces = 0,
    this.piping = 0,
    this.otherStyling = 0,
    this.urgentDelivery = false,
    this.urgentDeliveryFee = 500,
  });

  factory BillingDetails.fromJson(Map<String, dynamic> json) {
    return BillingDetails(
      baseStitching: (json['baseStitching'] as num).toDouble(),
      laces: (json['laces'] as num?)?.toDouble() ?? 0,
      piping: (json['piping'] as num?)?.toDouble() ?? 0,
      otherStyling: (json['otherStyling'] as num?)?.toDouble() ?? 0,
      urgentDelivery: json['urgentDelivery'] as bool? ?? false,
      urgentDeliveryFee: (json['urgentDeliveryFee'] as num?)?.toDouble() ?? 500,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseStitching': baseStitching,
      'laces': laces,
      'piping': piping,
      'otherStyling': otherStyling,
      'urgentDelivery': urgentDelivery,
      'urgentDeliveryFee': urgentDeliveryFee,
    };
  }

  BillingDetails copyWith({
    double? baseStitching,
    double? laces,
    double? piping,
    double? otherStyling,
    bool? urgentDelivery,
    double? urgentDeliveryFee,
  }) {
    return BillingDetails(
      baseStitching: baseStitching ?? this.baseStitching,
      laces: laces ?? this.laces,
      piping: piping ?? this.piping,
      otherStyling: otherStyling ?? this.otherStyling,
      urgentDelivery: urgentDelivery ?? this.urgentDelivery,
      urgentDeliveryFee: urgentDeliveryFee ?? this.urgentDeliveryFee,
    );
  }
}
