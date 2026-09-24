import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_boutique/models/billing.dart';
import 'package:smart_boutique/models/customer.dart';
import 'package:smart_boutique/models/measurement.dart';
import 'package:smart_boutique/models/order.dart';
import 'package:smart_boutique/providers/customer_provider.dart';
import 'package:smart_boutique/providers/order_provider.dart';
import 'package:smart_boutique/services/fabric_calculator_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Smart Boutique Acceptance Criteria Verification', () {
    late SharedPreferences prefs;
    late CustomerProvider customerProvider;
    late OrderProvider orderProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      customerProvider = CustomerProvider(prefs);
      orderProvider = OrderProvider(prefs);
      await customerProvider.loadCustomers();
      await orderProvider.loadOrders();
    });

    test('1. Customer CRUD and Dynamic Search', () async {
      // Add Customer
      const measurement = Measurement(
        teera: 14.5,
        chest: 36.0,
        waist: 30.0,
        armhole: 16.0,
        length: 40.0,
      );

      final bool added = await customerProvider.addCustomer(
        name: 'Ayesha Khan',
        phone: '0300-1234567',
        measurement: measurement,
      );
      expect(added, isTrue);
      expect(customerProvider.customers.length, 1);

      final Customer customer = customerProvider.customers.first;
      expect(customer.name, 'Ayesha Khan');
      expect(customer.phone, '0300-1234567');
      expect(customer.id, startsWith('CUS-'));
      expect(customer.measurement.teera, 14.5);
      expect(customer.measurement.length, 40.0);

      // Search by Name
      customerProvider.setSearchQuery('Ayesha');
      expect(customerProvider.filteredCustomers.length, 1);

      // Search by Phone
      customerProvider.setSearchQuery('1234567');
      expect(customerProvider.filteredCustomers.length, 1);

      // Search non-existent
      customerProvider.setSearchQuery('XYZ');
      expect(customerProvider.filteredCustomers.isEmpty, isTrue);

      // Edit Customer
      final updated = customer.copyWith(
        name: 'Ayesha Khan (VIP)',
        measurement: customer.measurement.copyWith(waist: 31.0),
      );
      final bool updatedSuccess = await customerProvider.updateCustomer(updated);
      expect(updatedSuccess, isTrue);
      expect(customerProvider.findById(customer.id)?.name, 'Ayesha Khan (VIP)');
      expect(customerProvider.findById(customer.id)?.measurement.waist, 31.0);
    });

    test('2. Fabric Calculation for Garments', () {
      final service = FabricCalculatorService();

      // Anarkali Flare Kurti
      final anarkali = service.calculateFabric(
        designType: 'Anarkali Flare Kurti',
        height: 1.5,
        width: 2.0,
      );
      expect(anarkali, 3.25);
      expect(service.toYards(anarkali), closeTo(3.25 * 1.09361, 0.01));

      // Layered Frock
      final layered = service.calculateFabric(
        designType: 'Layered Frock',
        height: 2.0,
        width: 1.0,
      );
      expect(layered, 4.35);

      // Straight Kurti
      final straight = service.calculateFabric(
        designType: 'Straight Kurti',
        height: 1.5,
        width: 1.0,
      );
      expect(straight, 2.10);

      // Invalid dimensions throw FabricCalculatorException
      expect(
        () => service.calculateFabric(
          designType: 'Basic Shirt',
          height: -1,
          width: 2,
        ),
        throwsA(isA<FabricCalculatorException>()),
      );
    });

    test('3. Order State Machine and Transitions', () async {
      final bool added = await customerProvider.addCustomer(
        name: 'Fatima Ali',
        phone: '0321-9876543',
        measurement: const Measurement(
          teera: 15.0,
          chest: 38.0,
          waist: 32.0,
          armhole: 17.0,
          length: 42.0,
        ),
      );
      expect(added, isTrue);
      final customer = customerProvider.customers.first;

      final order = await orderProvider.createOrder(
        customer: customer,
        garmentType: 'Anarkali Flare Kurti',
        measurements: customer.measurement,
        fabricMeters: 3.25,
        fabricYards: 3.55,
        billing: const BillingDetails(
          baseStitching: 1500,
          laces: 300,
          piping: 200,
          otherStyling: 0,
          urgentDelivery: true,
          urgentDeliveryFee: 500,
        ),
      );

      expect(order, isNotNull);
      expect(order!.id, startsWith('ORD-'));
      expect(order.status, OrderStatus.pending);
      expect(order.totalBill, 2500);

      // Advance: Pending -> Cutting
      bool advanced = await orderProvider.advanceStatus(order.id);
      expect(advanced, isTrue);
      expect(orderProvider.findById(order.id)?.status, OrderStatus.cutting);

      // Advance: Cutting -> Stitching
      advanced = await orderProvider.advanceStatus(order.id);
      expect(advanced, isTrue);
      expect(orderProvider.findById(order.id)?.status, OrderStatus.stitching);

      // Advance: Stitching -> Ready
      advanced = await orderProvider.advanceStatus(order.id);
      expect(advanced, isTrue);
      expect(orderProvider.findById(order.id)?.status, OrderStatus.ready);

      // Advance: Ready -> Delivered
      advanced = await orderProvider.advanceStatus(order.id);
      expect(advanced, isTrue);
      expect(orderProvider.findById(order.id)?.status, OrderStatus.delivered);

      // Once delivered, cannot advance further
      advanced = await orderProvider.advanceStatus(order.id);
      expect(advanced, isFalse);

      // Invalid backward transition is prevented
      final bool backward = await orderProvider.updateStatus(
        order.id,
        OrderStatus.cutting,
      );
      expect(backward, isFalse);

      // Reset workflow back to Pending works
      final bool reset = await orderProvider.resetStatus(order.id);
      expect(reset, isTrue);
      expect(orderProvider.findById(order.id)?.status, OrderStatus.pending);
    });

    test('4. Billing Calculations and Updates', () async {
      await customerProvider.addCustomer(
        name: 'Zainab Bibi',
        phone: '0333-5551234',
        measurement: const Measurement(
          teera: 14.0,
          chest: 34.0,
          waist: 28.0,
          armhole: 15.5,
          length: 38.0,
        ),
      );
      final customer = customerProvider.customers.first;

      final order = await orderProvider.createOrder(
        customer: customer,
        garmentType: 'Straight Kurti',
        measurements: customer.measurement,
        fabricMeters: 2.10,
        fabricYards: 2.30,
        billing: const BillingDetails(
          baseStitching: 1500,
          laces: 300,
          piping: 200,
          otherStyling: 100,
          urgentDelivery: false,
        ),
      );

      expect(order, isNotNull);
      // Subtotal = 1500 + 300 + 200 + 100 = 2100. Urgent = false. Total = 2100.
      expect(order!.totalBill, 2100);

      // Update billing to include urgent delivery
      final updatedBilling = order.billing.copyWith(
        urgentDelivery: true,
        urgentDeliveryFee: 500,
      );
      final bool updated = await orderProvider.updateBilling(
        order.id,
        updatedBilling,
      );
      expect(updated, isTrue);
      expect(orderProvider.findById(order.id)?.totalBill, 2600);
    });

    test('5. Offline Persistence Across App Restart', () async {
      // 1. Add data in current session
      await customerProvider.addCustomer(
        name: 'Persistent Customer',
        phone: '0312-3456789',
        measurement: const Measurement(
          teera: 14.0,
          chest: 35.0,
          waist: 29.0,
          armhole: 16.0,
          length: 41.0,
        ),
      );
      final customer = customerProvider.customers.first;

      await orderProvider.createOrder(
        customer: customer,
        garmentType: 'Layered Frock',
        measurements: customer.measurement,
        fabricMeters: 4.35,
        fabricYards: 4.76,
        billing: const BillingDetails(
          baseStitching: 3000,
          laces: 400,
          piping: 100,
          otherStyling: 0,
          urgentDelivery: true,
          urgentDeliveryFee: 500,
        ),
      );

      // 2. Simulate closing app and reopening by initializing brand new provider instances with the same SharedPreferences
      final newCustomerProvider = CustomerProvider(prefs);
      final newOrderProvider = OrderProvider(prefs);
      await newCustomerProvider.loadCustomers();
      await newOrderProvider.loadOrders();

      // 3. Verify data persisted
      expect(newCustomerProvider.customers.length, 1);
      expect(newCustomerProvider.customers.first.name, 'Persistent Customer');
      expect(newCustomerProvider.customers.first.measurement.chest, 35.0);

      expect(newOrderProvider.orders.length, 1);
      final persistedOrder = newOrderProvider.orders.first;
      expect(persistedOrder.customerName, 'Persistent Customer');
      expect(persistedOrder.garmentType, 'Layered Frock');
      expect(persistedOrder.totalBill, 4000);
      expect(persistedOrder.status, OrderStatus.pending);
    });
  });
}
