import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/customer.dart';
import '../models/measurement.dart';
import '../services/storage_service.dart';

class CustomerProvider extends ChangeNotifier {
  CustomerProvider(SharedPreferences prefs)
      : _storage = StorageService(prefs);

  final StorageService _storage;

  List<Customer> _customers = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  List<Customer> get customers => List.unmodifiable(_customers);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  List<Customer> get filteredCustomers {
    final String query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return customers;
    }
    return _customers.where((customer) {
      return customer.name.toLowerCase().contains(query) ||
          customer.phone.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> loadCustomers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _customers = await _storage.getCustomers();
      _customers.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {
      _errorMessage = 'Unable to load customers.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Customer? findById(String id) {
    try {
      return _customers.firstWhere((customer) => customer.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> addCustomer({
    required String name,
    required String phone,
    required Measurement measurement,
  }) async {
    try {
      final DateTime now = DateTime.now();
      final Customer customer = Customer(
        id: _nextCustomerId(now),
        name: name.trim(),
        phone: phone.trim(),
        measurement: measurement,
        createdAt: now,
        updatedAt: now,
      );
      _customers = [..._customers, customer];
      await _persist();
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Unable to save customer. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCustomer(Customer updated) async {
    try {
      final int index = _customers.indexWhere((item) => item.id == updated.id);
      if (index < 0) {
        _errorMessage = 'Unable to save customer. Please try again.';
        notifyListeners();
        return false;
      }
      _customers = [..._customers];
      _customers[index] = updated.copyWith(updatedAt: DateTime.now());
      await _persist();
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Unable to save customer. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCustomer(String id) async {
    try {
      _customers = _customers.where((customer) => customer.id != id).toList();
      await _persist();
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Unable to delete customer. Please try again.';
      notifyListeners();
      return false;
    }
  }

  String _nextCustomerId(DateTime now) {
    final int year = now.year;
    int maxSequence = 0;
    final RegExp pattern = RegExp(r'^CUS-(\d{4})-(\d{4})$');
    for (final Customer customer in _customers) {
      final Match? match = pattern.firstMatch(customer.id);
      if (match == null) {
        continue;
      }
      if (int.parse(match.group(1)!) == year) {
        final int sequence = int.parse(match.group(2)!);
        if (sequence > maxSequence) {
          maxSequence = sequence;
        }
      }
    }
    return 'CUS-$year-${(maxSequence + 1).toString().padLeft(4, '0')}';
  }

  Future<void> seedSampleCustomers() async {
    final DateTime now = DateTime.now();
    _customers = [
      Customer(
        id: 'CUS-${now.year}-0001',
        name: 'Ayesha Khan',
        phone: '0300-1234567',
        measurement: const Measurement(
          teera: 14.5,
          chest: 36.0,
          waist: 30.0,
          armhole: 16.0,
          length: 40.0,
        ),
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      Customer(
        id: 'CUS-${now.year}-0002',
        name: 'Fatima Ali',
        phone: '0321-9876543',
        measurement: const Measurement(
          teera: 15.0,
          chest: 38.0,
          waist: 32.0,
          armhole: 17.0,
          length: 42.0,
        ),
        createdAt: now.subtract(const Duration(days: 8)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      Customer(
        id: 'CUS-${now.year}-0003',
        name: 'Zainab Bibi',
        phone: '0333-5551234',
        measurement: const Measurement(
          teera: 14.0,
          chest: 34.0,
          waist: 28.0,
          armhole: 15.5,
          length: 38.0,
        ),
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      Customer(
        id: 'CUS-${now.year}-0004',
        name: 'Hina Tariq',
        phone: '0345-4447890',
        measurement: const Measurement(
          teera: 14.5,
          chest: 37.0,
          waist: 31.0,
          armhole: 16.5,
          length: 39.0,
        ),
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now,
      ),
    ];
    await _persist();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _customers = [];
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    await _storage.saveCustomers(_customers);
  }
}
