import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show sqfliteFfiInit, databaseFactoryFfi;

/// Acceso único a la base de datos SQLite local.
///
/// En Android/iOS usa sqflite nativo; en escritorio y tests usa la
/// implementación FFI. Llamar a [AppDatabase.init] antes de usarla.
class AppDatabase {
  AppDatabase._();

  static const _name = 'creathor.db';

  /// v1: esquema inicial con datos de ejemplo.
  /// v2: tabla `incomes` y eliminación de los datos de ejemplo.
  static const _version = 2;

  /// Cadenas disponibles en el comparador desde el primer arranque.
  /// Es catálogo de configuración, no datos de ejemplo: se pueden añadir más
  /// desde la pantalla de supermercado.
  static const defaultSupermarkets = ['Mercadona', 'Carrefour', 'Lidl', 'Dia'];

  static Database? _db;

  static Database get instance {
    final db = _db;
    if (db == null) {
      throw StateError('AppDatabase.init() no ha sido llamado');
    }
    return db;
  }

  /// [inMemory] abre una base de datos efímera (tests).
  /// [path] permite a los tests usar un fichero concreto.
  static Future<Database> init({
    bool inMemory = false,
    @visibleForTesting String? path,
  }) async {
    if (_db != null) return _db!;

    if (inMemory || path != null || _needsFfi) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    path ??= inMemory
        ? inMemoryDatabasePath
        : p.join(await getDatabasesPath(), _name);

    _db = await openDatabase(
      path,
      version: _version,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) async {
        await _createSchema(db);
        await _createIncomes(db);
        await _insertDefaultSupermarkets(db);
      },
      onUpgrade: (db, oldVersion, _) async {
        if (oldVersion < 2) {
          await _createIncomes(db);
          await _removeSeedData(db);
        }
      },
    );
    return _db!;
  }

  static bool get _needsFfi {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux;
  }

  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  static Future<void> _insertDefaultSupermarkets(DatabaseExecutor db) async {
    for (final name in defaultSupermarkets) {
      await db.insert('supermarkets', {
        'name': name,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  /// La v1 rellenaba la base con campañas, gastos, productos y deadlines de
  /// ejemplo. Se borran todos esos registros; se conservan los supermercados.
  static Future<void> _removeSeedData(Database db) async {
    await db.transaction((txn) async {
      for (final table in [
        'deadline_tasks',
        'deadlines',
        'deliverables',
        'campaigns',
        'expenses',
        'cart_items',
        'product_prices',
        'products',
      ]) {
        await txn.delete(table);
      }
      await txn.delete(
        'sqlite_sequence',
        where: 'name IN (?, ?, ?, ?, ?, ?, ?, ?)',
        whereArgs: [
          'deadline_tasks',
          'deadlines',
          'deliverables',
          'campaigns',
          'expenses',
          'cart_items',
          'product_prices',
          'products',
        ],
      );
      await _insertDefaultSupermarkets(txn);
    });
  }

  static Future<void> _createIncomes(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS incomes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        amount REAL NOT NULL,
        date TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_incomes_date ON incomes(date)',
    );
  }

  static Future<void> _createSchema(Database db) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE campaigns (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        brand TEXT NOT NULL,
        title TEXT NOT NULL,
        gross_fee REAL NOT NULL,
        agency_pct REAL NOT NULL DEFAULT 0,
        tax_pct REAL NOT NULL DEFAULT 0,
        terms TEXT NOT NULL DEFAULT '30',
        status TEXT NOT NULL DEFAULT 'production',
        created_at TEXT NOT NULL,
        invoice_date TEXT,
        due_date TEXT,
        draft_deadline TEXT,
        publish_date TEXT,
        contact_name TEXT,
        contact_role TEXT,
        agency_name TEXT,
        note TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE deliverables (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        campaign_id INTEGER NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        note TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        deductible_pct REAL NOT NULL DEFAULT 100,
        has_receipt INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE supermarkets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    batch.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        note TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE product_prices (
        product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
        supermarket_id INTEGER NOT NULL REFERENCES supermarkets(id) ON DELETE CASCADE,
        price REAL NOT NULL,
        PRIMARY KEY (product_id, supermarket_id)
      )
    ''');

    batch.execute('''
      CREATE TABLE cart_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
        quantity INTEGER NOT NULL DEFAULT 1,
        checked INTEGER NOT NULL DEFAULT 0,
        added_at TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE deadlines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        campaign_id INTEGER REFERENCES campaigns(id) ON DELETE SET NULL,
        title TEXT NOT NULL,
        description TEXT,
        type TEXT NOT NULL,
        date_time TEXT NOT NULL,
        all_day INTEGER NOT NULL DEFAULT 0,
        done INTEGER NOT NULL DEFAULT 0,
        awaiting_approval INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE deadline_tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        deadline_id INTEGER NOT NULL REFERENCES deadlines(id) ON DELETE CASCADE,
        label TEXT NOT NULL,
        done INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    batch.execute('CREATE INDEX idx_deadlines_date ON deadlines(date_time)');
    batch.execute('CREATE INDEX idx_campaigns_status ON campaigns(status)');
    batch.execute('CREATE INDEX idx_expenses_date ON expenses(date)');

    await batch.commit(noResult: true);
  }
}
