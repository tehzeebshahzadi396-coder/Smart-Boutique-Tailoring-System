import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/customer.dart';
import '../models/order.dart';
import '../utils/app_constants.dart';

class StorageService {
  StorageService(this._prefs);

  final SharedPreferences _prefs;

  Future<void> saveCustomers(List<Customer> customers) async {
    final String encoded = jsonEncode(
      customers.map((customer) => customer.toJson()).toList(),
    );
    final bool saved = await _prefs.setString(
      AppConstants.customersStorageKey,
      encoded,
    );
    if (!saved) {
      throw const StorageException('Unable to save customer.');
    }
  }

  Future<List<Customer>> getCustomers() async {
    final String? raw = _prefs.getString(AppConstants.customersStorageKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Customer.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> saveOrders(List<Order> orders) async {
    final String encoded = jsonEncode(
      orders.map((order) => order.toJson()).toList(),
    );
    final bool saved = await _prefs.setString(
      AppConstants.ordersStorageKey,
      encoded,
    );
    if (!saved) {
      throw const StorageException('Unable to save order.');
    }
  }

  Future<List<Order>> getOrders() async {
    final String? raw = _prefs.getString(AppConstants.ordersStorageKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Order.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }
}

class StorageException implements Exception {
  const StorageException(this.message);

  final String message;

  @override
  String toString() => message;
}
