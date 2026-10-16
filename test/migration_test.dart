import 'dart:io';

import 'package:creathor/core/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory dir;
  late String path;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('creathor_migration');
    path = p.join(dir.path, 'creathor.db');
  });

  tearDown(() async {
    await AppDatabase.close();
    await dir.delete(recursive: true);
  });

  test('v1 → v2 crea incomes y borra los datos de ejemplo', () async {
    // Simula una instalación v1: esquema completo con datos y sin `incomes`.
    var db = await AppDatabase.init(path: path);
    final campaignId = await db.insert('campaigns', {
      'brand': 'Spotify España',
      'title': 'Demo',
      'gross_fee': 3200.0,
      'created_at': DateTime.now().toIso8601String(),
    });
    await db.insert('deliverables', {'campaign_id': campaignId, 'name': 'x'});
    await db.insert('expenses', {
      'title': 'Adobe',
      'amount': 62.99,
      'category': 'software',
      'date': DateTime.now().toIso8601String(),
    });
    final productId = await db.insert('products', {'name': 'Café'});
    await db.insert('cart_items', {
      'product_id': productId,
      'added_at': DateTime.now().toIso8601String(),
    });
    await db.insert('deadlines', {
      'title': 'Rodaje',
      'type': 'rodaje',
      'date_time': DateTime.now().toIso8601String(),
    });
    await db.execute('DROP TABLE incomes');
    await db.setVersion(1);
    await AppDatabase.close();

    db = await AppDatabase.init(path: path);

    expect(await db.getVersion(), 2);
    for (final table in [
      'campaigns',
      'deliverables',
      'expenses',
      'products',
      'cart_items',
      'deadlines',
      'deadline_tasks',
      'incomes',
    ]) {
      expect(await db.query(table), isEmpty, reason: table);
    }
    final supers = await db.query('supermarkets', orderBy: 'id');
    expect(supers.map((r) => r['name']), AppDatabase.defaultSupermarkets);
  });
}
