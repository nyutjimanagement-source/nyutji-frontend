import 'package:intl/intl.dart';

class Formatters {
  static String currencyIdr(double amount) {
    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return currencyFormatter.format(amount);
  }
}
