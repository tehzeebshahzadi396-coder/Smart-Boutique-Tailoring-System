import 'package:intl/intl.dart';

import 'app_constants.dart';

class Formatters {
  Formatters._();

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_PK',
    symbol: '${AppConstants.currencySymbol} ',
    decimalDigits: 0,
  );

  static final DateFormat _date = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTime = DateFormat('dd MMM yyyy, hh:mm a');

  static String currency(double amount) => _currency.format(amount);

  static String date(DateTime value) => _date.format(value);

  static String dateTime(DateTime value) => _dateTime.format(value);

  static String meters(double value) => '${value.toStringAsFixed(2)} meters';

  static String yards(double value) => '${value.toStringAsFixed(2)} yards';
}
