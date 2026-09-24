import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/billing.dart';
import '../models/customer.dart';
import '../models/measurement.dart';
import '../models/order.dart';
import '../services/billing_calculator_service.dart';
import '../services/order_id_service.dart';
import '../services/storage_service.dart';
import '../utils/app_constants.dart';

class OrderProvider extends ChangeNotifier {
  OrderProvider(SharedPreferences prefs)
      : _storage = StorageService(prefs),
        _orderIdService = OrderIdService(),
        _billingCalculator = BillingCalculatorService();

  final StorageService _storage;
  final OrderIdService _orderIdService;
  final BillingCalculatorService _billingCalculator;

  List<Order> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  OrderStatus? _statusFilter;

  List<Order> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  OrderStatus? get statusFilter => _statusFilter;

  int get customerFacingActiveCount {
    return _orders.where((order) => order.status != OrderStatus.delivered).length;
  }

  int get pendingOrders => _count(OrderStatus.pending);
  int get cuttingOrders => _count(OrderStatus.cutting);
  int get stitchingOrders => _count(OrderStatus.stitching);
  int get readyOrders => _count(OrderStatus.ready);
  int get deliveredOrders => _count(OrderStatus.delivered);

  List<Order> get recentOrders {
    final List<Order> sorted = [..._orders]
      ..sort((a, b) => b.orderDate.compareTo(a.orderDate));
    return sorted.take(5).toList();
  }

  List<Order> get filteredOrders {
    Iterable<Order> result = _orders;
    if (_statusFilter != null) {
      result = result.where((order) => order.status == _statusFilter);
    }
    final String query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((order) {
        return order.id.toLowerCase().contains(query) ||
            order.customerName.toLowerCase().contains(query) ||
            order.phone.toLowerCase().contains(query);
      });
    }
    final List<Order> list = result.toList()
      ..sort((a, b) => b.orderDate.compareTo(a.orderDate));
    return list;
  }

  Future<void> loadOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _orders = await _storage.getOrders();
      _orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    } catch (_) {
      _errorMessage = 'Unable to load orders.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(OrderStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  Order? findById(String id) {
    try {
      return _orders.firstWhere((order) => order.id == id);
    } catch (_) {
      return null;
    }
  }

  String previewNextOrderId({DateTime? now}) {
    return _orderIdService.generateNext(
      existingIds: _orders.map((order) => order.id).toList(),
      now: now,
    );
  }

  Future<Order?> createOrder({
    required Customer customer,
    required String garmentType,
    required Measurement measurements,
    required double fabricMeters,
    required double fabricYards,
    required BillingDetails billing,
    DateTime? orderDate,
    DateTime? expectedDeliveryDate,
  }) async {
    try {
      final DateTime createdAt = orderDate ?? DateTime.now();
      final int deliveryDays = billing.urgentDelivery
          ? AppConstants.urgentDeliveryDays
          : AppConstants.defaultDeliveryDays;
      final Order order = Order(
        id: previewNextOrderId(now: createdAt),
        customerId: customer.id,
        customerName: customer.name,
        phone: customer.phone,
        garmentType: garmentType,
        measurements: measurements,
        fabricMeters: fabricMeters,
        fabricYards: fabricYards,
        billing: billing,
        orderDate: createdAt,
        expectedDeliveryDate: expectedDeliveryDate ??
            createdAt.add(Duration(days: deliveryDays)),
        status: OrderStatus.pending,
      );
      _orders = [order, ..._orders];
      await _persist();
      notifyListeners();
      return order;
    } catch (_) {
      _errorMessage = 'Unable to create order. Please try again.';
      notifyListeners();
      return null;
    }
  }

  Future<bool> advanceStatus(String orderId) async {
    final Order? current = findById(orderId);
    if (current == null || !current.status.canAdvance) {
      return false;
    }
    return updateStatus(orderId, current.status.next!);
  }

  Future<bool> updateStatus(String orderId, OrderStatus nextStatus) async {
    final Order? current = findById(orderId);
    if (current == null) {
      return false;
    }
    if (nextStatus.index < current.status.index) {
      _errorMessage = 'Status cannot move backwards. Use reset if needed.';
      notifyListeners();
      return false;
    }
    if (nextStatus.index > current.status.index + 1) {
      _errorMessage = 'Please update the order one stage at a time.';
      notifyListeners();
      return false;
    }
    return _replace(current.copyWith(status: nextStatus));
  }

  Future<bool> resetStatus(String orderId) async {
    final Order? current = findById(orderId);
    if (current == null) {
      return false;
    }
    return _replace(current.copyWith(status: OrderStatus.pending));
  }

  Future<bool> updateBilling(String orderId, BillingDetails billing) async {
    final Order? current = findById(orderId);
    if (current == null) {
      return false;
    }
    return _replace(current.copyWith(billing: billing));
  }

  double calculateTotal(BillingDetails billing) {
    return _billingCalculator.totalFrom(billing);
  }

  Future<bool> _replace(Order updated) async {
    try {
      final int index = _orders.indexWhere((order) => order.id == updated.id);
      if (index < 0) {
        return false;
      }
      _orders = [..._orders];
      _orders[index] = updated;
      await _persist();
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Unable to update order. Please try again.';
      notifyListeners();
      return false;
    }
  }

  int _count(OrderStatus status) {
    return _orders.where((order) => order.status == status).length;
  }

  Future<void> seedSampleOrders(List<Customer> customers) async {
    if (customers.isEmpty) {
      return;
    }
    final DateTime now = DateTime.now();
    final Customer c1 = customers[0];
    final Customer c2 = customers.length > 1 ? customers[1] : c1;
    final Customer c3 = customers.length > 2 ? customers[2] : c1;
    final Customer c4 = customers.length > 3 ? customers[3] : c1;

    _orders = [
      Order(
        id: 'ORD-${now.year}-0001',
        customerId: c1.id,
        customerName: c1.name,
        phone: c1.phone,
        garmentType: 'Anarkali Flare Kurti',
        measurements: c1.measurement,
        fabricMeters: 3.25,
        fabricYards: 3.55,
        billing: const BillingDetails(
          baseStitching: 2500,
          laces: 300,
          piping: 200,
          otherStyling: 0,
          urgentDelivery: true,
          urgentDeliveryFee: 500,
        ),
        orderDate: now.subtract(const Duration(days: 5)),
        expectedDeliveryDate: now.add(const Duration(days: 2)),
        status: OrderStatus.stitching,
      ),
      Order(
        id: 'ORD-${now.year}-0002',
        customerId: c2.id,
        customerName: c2.name,
        phone: c2.phone,
        garmentType: 'Layered Frock',
        measurements: c2.measurement,
        fabricMeters: 4.35,
        fabricYards: 4.76,
        billing: const BillingDetails(
          baseStitching: 3000,
          laces: 400,
          piping: 0,
          otherStyling: 200,
          urgentDelivery: false,
        ),
        orderDate: now.subtract(const Duration(days: 6)),
        expectedDeliveryDate: now.add(const Duration(days: 1)),
        status: OrderStatus.ready,
      ),
      Order(
        id: 'ORD-${now.year}-0003',
        customerId: c3.id,
        customerName: c3.name,
        phone: c3.phone,
        garmentType: 'Straight Kurti',
        measurements: c3.measurement,
        fabricMeters: 2.10,
        fabricYards: 2.30,
        billing: const BillingDetails(
          baseStitching: 1500,
          laces: 0,
          piping: 150,
          otherStyling: 0,
          urgentDelivery: false,
        ),
        orderDate: now.subtract(const Duration(days: 2)),
        expectedDeliveryDate: now.add(const Duration(days: 5)),
        status: OrderStatus.cutting,
      ),
      Order(
        id: 'ORD-${now.year}-0004',
        customerId: c4.id,
        customerName: c4.name,
        phone: c4.phone,
        garmentType: 'Basic Shirt',
        measurements: c4.measurement,
        fabricMeters: 1.80,
        fabricYards: 1.97,
        billing: const BillingDetails(
          baseStitching: 1200,
          laces: 0,
          piping: 0,
          otherStyling: 0,
          urgentDelivery: false,
        ),
        orderDate: now.subtract(const Duration(days: 12)),
        expectedDeliveryDate: now.subtract(const Duration(days: 5)),
        status: OrderStatus.delivered,
      ),
    ];
    await _persist();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _orders = [];
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    await _storage.saveOrders(_orders);
  }
}
