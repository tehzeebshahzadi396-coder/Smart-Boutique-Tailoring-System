/// Centralized labels, storage keys, and business defaults.
class AppConstants {
  AppConstants._();

  static const String appName = 'Smart Boutique';
  static const String appFullName = 'Smart Boutique & Tailoring Management System';
  static const String currencySymbol = 'Rs.';
  static const String currencyCode = 'PKR';

  static const String customersStorageKey = 'smart_boutique_customers';
  static const String ordersStorageKey = 'smart_boutique_orders';

  static const double metersToYards = 1.09361;
  static const double defaultUrgentDeliveryFee = 500;
  static const int defaultDeliveryDays = 7;
  static const int urgentDeliveryDays = 3;

  static const List<String> garmentDesigns = [
    'Anarkali Flare Kurti',
    'Layered Frock',
    'Straight Kurti',
    'A-Line Frock',
    'Basic Shirt',
  ];

  static const Map<String, double> defaultStitchingCosts = {
    'Anarkali Flare Kurti': 2500,
    'Layered Frock': 3000,
    'Straight Kurti': 1500,
    'A-Line Frock': 2200,
    'Basic Shirt': 1200,
  };

  static const String fabricEstimateDisclaimer =
      'Estimated calculations only. Actual fabric depends on fabric width, '
      'cutting layout, sleeves, flare, and tailoring practices.';
}
