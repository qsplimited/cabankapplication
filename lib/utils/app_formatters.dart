import 'package:intl/intl.dart';

class AppFormatters {
  // Configured for Indian Rupee with Lakhs/Crores grouping
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Formats a double value to Indian Rupee string: 100000 -> ₹1,00,00,0.00
  static String formatCurrency(double amount) {
    return _currencyFormatter.format(amount);
  }

  /// Optional: Format date for Indian banking standards
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }
}