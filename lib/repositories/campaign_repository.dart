import 'package:sqflite/sqflite.dart';

import '../core/db/app_database.dart';
import '../models/campaign.dart';

class CampaignRepository {
  Database get _db => AppDatabase.instance;

  Future<List<Campaign>> all() async {
    final rows = await _db.query('campaigns', orderBy: 'created_at DESC');
    return rows.map(Campaign.fromMap).toList();
  }

  Future<Campaign?> byId(int id) async {
    final rows = await _db.query('campaigns', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Campaign.fromMap(rows.first);
  }

  Future<List<Deliverable>> deliverables(int campaignId) async {
    final rows = await _db.query(
      'deliverables',
      where: 'campaign_id = ?',
      whereArgs: [campaignId],
      orderBy: 'id',
    );
    return rows.map(Deliverable.fromMap).toList();
  }

  /// Resumen de entregables por campaña para las tarjetas del dashboard.
  Future<Map<int, List<Deliverable>>> deliverablesByCampaign() async {
    final rows = await _db.query('deliverables', orderBy: 'id');
    final map = <int, List<Deliverable>>{};
    for (final r in rows) {
      final d = Deliverable.fromMap(r);
      map.putIfAbsent(d.campaignId, () => []).add(d);
    }
    return map;
  }

  Future<int> insert(Campaign c, List<String> deliverableNames) async {
    return _db.transaction((txn) async {
      final id = await txn.insert('campaigns', c.toMap()..remove('id'));
      for (final name in deliverableNames) {
        await txn.insert('deliverables', {
          'campaign_id': id,
          'name': name,
          'status': DeliverableStatus.pending.db,
        });
      }
      return id;
    });
  }

  Future<void> update(Campaign c) async {
    await _db.update(
      'campaigns',
      c.toMap(),
      where: 'id = ?',
      whereArgs: [c.id],
    );
  }

  Future<void> delete(int id) async {
    await _db.delete('campaigns', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> addDeliverable(int campaignId, String name) =>
      _db.insert('deliverables', {
        'campaign_id': campaignId,
        'name': name,
        'status': DeliverableStatus.pending.db,
      });

  Future<void> updateDeliverable(Deliverable d) async {
    await _db.update(
      'deliverables',
      d.toMap(),
      where: 'id = ?',
      whereArgs: [d.id],
    );
  }

  Future<void> deleteDeliverable(int id) async {
    await _db.delete('deliverables', where: 'id = ?', whereArgs: [id]);
  }
}
