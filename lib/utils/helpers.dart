import 'package:intl/intl.dart';

class AppHelpers {
  static String formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  static String formatPrice(double price) {
    return NumberFormat.currency(
      locale: 'pl_PL',
      symbol: 'zł',
      decimalDigits: 2,
    ).format(price);
  }

  static double calculateDailyUsage(double amount, int days) {
    return days > 0 ? amount / days : 0.0;
  }
}