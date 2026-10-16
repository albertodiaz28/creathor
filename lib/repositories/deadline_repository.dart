import 'package:sqflite/sqflite.dart';

import '../core/db/app_database.dart';
import '../models/deadline.dart';

class DeadlineRepository {
  Database get _db => AppDatabase.instance;

  static const _select = '''
    SELECT d.*, c.brand AS brand
    FROM deadlines d
    LEFT JOIN campaigns c ON c.id = d.campaign_id
  ''';

  Future<List<Deadline>> between(DateTime from, DateTime to) async {
    final rows = await _db.rawQuery(
      '$_select WHERE d.date_time >= ? AND d.date_time < ? ORDER BY d.date_time',
      [from.toIso8601String(), to.toIso8601String()],
    );
    return _withTasks(rows.map(Deadline.fromMap).toList());
  }

  Future<List<Deadline>> all() async {
    final rows = await _db.rawQuery('$_select ORDER BY d.date_time');
    return _withTasks(rows.map(Deadline.fromMap).toList());
  }

  Future<List<Deadline>> forCampaign(int campaignId) async {
    final rows = await _db.rawQuery(
      '$_select WHERE d.campaign_id = ? ORDER BY d.date_time',
      [campaignId],
    );
    return _withTasks(rows.map(Deadline.fromMap).toList());
  }

  Future<List<Deadline>> _withTasks(List<Deadline> list) async {
    if (list.isEmpty) return list;
    final ids = list.map((d) => d.id!).toList();
    final rows = await _db.query(
      'deadline_tasks',
      where: 'deadline_id IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: ids,
      orderBy: 'id',
    );
    final tasks = <int, List<DeadlineTask>>{};
    for (final r in rows) {
      final t = DeadlineTask.fromMap(r);
      tasks.putIfAbsent(t.deadlineId, () => []).add(t);
    }
    return [for (final d in list) d.copyWith(tasks: tasks[d.id] ?? const [])];
  }

  Future<int> insert(Deadline d, {List<String> tasks = const []}) {
    return _db.transaction((txn) async {
      final id = await txn.insert('deadlines', d.toMap()..remove('id'));
      for (final label in tasks) {
        await txn.insert('deadline_tasks', {
          'deadline_id': id,
          'label': label,
          'done': 0,
        });
      }
      return id;
    });
  }

  Future<void> update(Deadline d) async {
    await _db.update(
      'deadlines',
      d.toMap(),
      where: 'id = ?',
      whereArgs: [d.id],
    );
  }

  Future<void> delete(int id) async {
    await _db.delete('deadlines', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> addTask(int deadlineId, String label) => _db.insert(
    'deadline_tasks',
    {'deadline_id': deadlineId, 'label': label, 'done': 0},
  );

  Future<void> updateTask(DeadlineTask t) async {
    await _db.update(
      'deadline_tasks',
      t.toMap(),
      where: 'id = ?',
      whereArgs: [t.id],
    );
  }

  Future<void> deleteTask(int id) async {
    await _db.delete('deadline_tasks', where: 'id = ?', whereArgs: [id]);
  }
}
