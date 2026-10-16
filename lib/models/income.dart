/// Ingreso neto de trabajos ajenos a campañas (no se descuenta IVA ni IRPF).
class Income {
  const Income({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    this.description,
  });

  final int? id;
  final String title;
  final String? description;

  /// Importe neto que llega a la cuenta.
  final double amount;
  final DateTime date;

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'amount': amount,
    'date': date.toIso8601String(),
  };

  static Income fromMap(Map<String, Object?> m) => Income(
    id: m['id'] as int?,
    title: m['title'] as String,
    description: m['description'] as String?,
    amount: (m['amount'] as num).toDouble(),
    date: DateTime.parse(m['date'] as String),
  );
}
