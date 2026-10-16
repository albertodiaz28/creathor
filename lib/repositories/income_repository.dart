import 'package:sqflite/sqflite.dart';

import '../core/db/app_database.dart';
import '../models/income.dart';

class IncomeRepository {
  Database get _db => AppDatabase.instance;

  Future<List<Income>> all() async {
    final rows = await _db.query('incomes', orderBy: 'date DESC, id DESC');
    return rows.map(Income.fromMap).toList();
  }

  Future<int> insert(Income i) =>
      _db.insert('incomes', i.toMap()..remove('id'));

  Future<void> delete(int id) async {
    await _db.delete('incomes', where: 'id = ?', whereArgs: [id]);
  }
}
