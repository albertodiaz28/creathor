import 'package:flutter/material.dart';

import '../core/constants.dart';

enum ExpenseCategory {
  software('software', 'Software', Icons.brush_outlined),
  utilities('utilities', 'Luz / Fibra', Icons.wifi),
  props('props', 'Atrezzo / Café', Icons.coffee_outlined),
  equipment('equipment', 'Equipo', Icons.videocam_outlined),
  travel('travel', 'Desplazamiento', Icons.directions_car_outlined),
  other('other', 'Otros', Icons.receipt_long_outlined);

  const ExpenseCategory(this.db, this.label, this.icon);
  final String db;
  final String label;
  final IconData icon;

  static ExpenseCategory fromDb(String v) =>
      values.firstWhere((e) => e.db == v, orElse: () => other);
}

class Expense {
  const Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.description,
    this.deductiblePct = 100,
    this.hasReceipt = false,
  });

  static const vatRate = kVatRate;

  final int? id;
  final String title;
  final String? description;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;

  /// Porcentaje del gasto que es deducible (p. ej. 30% teletrabajo).
  final double deductiblePct;
  final bool hasReceipt;

  /// IVA recuperable: la parte deducible del importe lleva IVA incluido.
  double get recoverableVat =>
      amount * deductiblePct / 100 * vatRate / (1 + vatRate);

  double get deductibleAmount => amount * deductiblePct / 100;

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'amount': amount,
    'category': category.db,
    'date': date.toIso8601String(),
    'deductible_pct': deductiblePct,
    'has_receipt': hasReceipt ? 1 : 0,
  };

  static Expense fromMap(Map<String, Object?> m) => Expense(
    id: m['id'] as int?,
    title: m['title'] as String,
    description: m['description'] as String?,
    amount: (m['amount'] as num).toDouble(),
    category: ExpenseCategory.fromDb(m['category'] as String),
    date: DateTime.parse(m['date'] as String),
    deductiblePct: (m['deductible_pct'] as num).toDouble(),
    hasReceipt: (m['has_receipt'] as int) == 1,
  );
}
