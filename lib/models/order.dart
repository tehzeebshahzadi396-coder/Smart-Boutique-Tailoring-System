import 'billing.dart';
import 'measurement.dart';

enum OrderStatus {
  pending,
  cutting,
  stitching,
  ready,
  delivered,
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.cutting:
        return 'Cutting';
      case OrderStatus.stitching:
        return 'Stitching';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.delivered:
        return 'Delivered';
    }
  }

  int get stepIndex => index;

  OrderStatus? get next {
    if (this == OrderStatus.delivered) {
      return null;
    }
    return OrderStatus.values[index + 1];
  }

  bool get canAdvance => next != null;
}

class Order {
  final String id;
  final String customerId;
  final String customerName;
  final String phone;
  final String garmentType;
  final Measurement measurements;
  final double fabricMeters;
  final double fabricYards;
  final BillingDetails billing;
  final DateTime orderDate;
  final DateTime expectedDeliveryDate;
  final OrderStatus status;

  const Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.phone,
    required this.garmentType,
    required this.measurements,
    required this.fabricMeters,
    required this.fabricYards,
    required this.billing,
    required this.orderDate,
    required this.expectedDeliveryDate,
    required this.status,
  });

  double get stitchingCost => billing.baseStitching;

  double get extraStylingCost =>
      billing.laces + billing.piping + billing.otherStyling;

  double get urgentDeliveryFee =>
      billing.urgentDelivery ? billing.urgentDeliveryFee : 0;

  double get totalBill => stitchingCost + extraStylingCost + urgentDeliveryFee;

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String,
      phone: json['phone'] as String,
      garmentType: json['garmentType'] as String,
      measurements: Measurement.fromJson(
        Map<String, dynamic>.from(json['measurements'] as Map),
      ),
      fabricMeters: (json['fabricMeters'] as num).toDouble(),
      fabricYards: (json['fabricYards'] as num).toDouble(),
      billing: BillingDetails.fromJson(
        Map<String, dynamic>.from(json['billing'] as Map),
      ),
      orderDate: DateTime.parse(json['orderDate'] as String),
      expectedDeliveryDate: DateTime.parse(json['expectedDeliveryDate'] as String),
      status: OrderStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'phone': phone,
      'garmentType': garmentType,
      'measurements': measurements.toJson(),
      'fabricMeters': fabricMeters,
      'fabricYards': fabricYards,
      'billing': billing.toJson(),
      'orderDate': orderDate.toIso8601String(),
      'expectedDeliveryDate': expectedDeliveryDate.toIso8601String(),
      'status': status.name,
    };
  }

  Order copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? phone,
    String? garmentType,
    Measurement? measurements,
    double? fabricMeters,
    double? fabricYards,
    BillingDetails? billing,
    DateTime? orderDate,
    DateTime? expectedDeliveryDate,
    OrderStatus? status,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      phone: phone ?? this.phone,
      garmentType: garmentType ?? this.garmentType,
      measurements: measurements ?? this.measurements,
      fabricMeters: fabricMeters ?? this.fabricMeters,
      fabricYards: fabricYards ?? this.fabricYards,
      billing: billing ?? this.billing,
      orderDate: orderDate ?? this.orderDate,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      status: status ?? this.status,
    );
  }
}
