import 'package:sqflite/sqflite.dart';

import '../core/db/app_database.dart';
import '../models/expense.dart';

class ExpenseRepository {
  Database get _db => AppDatabase.instance;

  Future<List<Expense>> all() async {
    final rows = await _db.query('expenses', orderBy: 'date DESC, id DESC');
    return rows.map(Expense.fromMap).toList();
  }

  Future<int> insert(Expense e) =>
      _db.insert('expenses', e.toMap()..remove('id'));

  Future<void> update(Expense e) async {
    await _db.update('expenses', e.toMap(), where: 'id = ?', whereArgs: [e.id]);
  }

  Future<void> delete(int id) async {
    await _db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }
}
