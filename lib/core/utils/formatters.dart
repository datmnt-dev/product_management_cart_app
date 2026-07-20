import 'package:intl/intl.dart';

final _currencyFormatter = NumberFormat.currency(
  locale: 'vi_VN',
  symbol: 'đ',
  decimalDigits: 0,
);

final _dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
final _shortDateFormatter = DateFormat('dd/MM/yyyy');

String formatCurrency(num value) => _currencyFormatter.format(value);

String formatDate(DateTime value) => _dateFormatter.format(value);

String formatShortDate(DateTime value) => _shortDateFormatter.format(value);
