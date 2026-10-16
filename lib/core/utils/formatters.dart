import 'package:intl/intl.dart';

final _euro = NumberFormat.currency(locale: 'es_ES', symbol: '€');
final _euroInt = NumberFormat.currency(
  locale: 'es_ES',
  symbol: '€',
  decimalDigits: 0,
);
final _plain = NumberFormat('#,##0.00', 'es_ES');

/// "4.820,00 €"
String euro(num value) => _euro.format(value);

/// "4.820 €" (sin decimales, para cifras grandes)
String euroInt(num value) => _euroInt.format(value.round());

/// "4.820,00" sin símbolo.
String euroPlain(num value) => _plain.format(value);

/// "+2.048 €" / "-672 €"
String euroSigned(num value) {
  final abs = euroInt(value.abs());
  if (value > 0) return '+$abs';
  if (value < 0) return '-$abs';
  return abs;
}

String percent(num value) => '${value.round()}%';

String shortDate(DateTime d) => DateFormat('d MMM', 'es').format(d);
String longDate(DateTime d) => DateFormat('EEEE d MMMM', 'es').format(d);
String monthYear(DateTime d) {
  final s = DateFormat('MMMM yyyy', 'es').format(d);
  return s[0].toUpperCase() + s.substring(1);
}

String timeOfDay(DateTime d) => '${DateFormat('HH:mm').format(d)}h';
String weekdayShort(DateTime d) {
  final s = DateFormat('EEE', 'es').format(d).replaceAll('.', '');
  return s[0].toUpperCase() + s.substring(1);
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Etiqueta relativa: "Hoy", "Mañana", "Jueves 17".
String relativeDayLabel(DateTime d) {
  final today = dateOnly(DateTime.now());
  final target = dateOnly(d);
  final diff = target.difference(today).inDays;
  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Mañana';
  if (diff == -1) return 'Ayer';
  final s = DateFormat('EEEE d', 'es').format(d);
  return s[0].toUpperCase() + s.substring(1);
}

/// Días hasta una fecha, en texto: "Vence en 12 días", "Vence hoy", "Vencida hace 3 días".
String dueLabel(DateTime due) {
  final diff = dateOnly(due).difference(dateOnly(DateTime.now())).inDays;
  if (diff == 0) return 'Vence hoy';
  if (diff == 1) return 'Vence mañana';
  if (diff > 1) return 'Vence en $diff días';
  if (diff == -1) return 'Vencida ayer';
  return 'Vencida hace ${-diff} días';
}
