import 'package:sqflite/sqflite.dart';

import '../core/db/app_database.dart';
import '../models/grocery.dart';

class GroceryRepository {
  Database get _db => AppDatabase.instance;

  static const _selectedKey = 'selected_supermarket';

  Future<List<Supermarket>> supermarkets() async {
    final rows = await _db.query('supermarkets', orderBy: 'id');
    return rows.map(Supermarket.fromMap).toList();
  }

  Future<int> addSupermarket(String name) =>
      _db.insert('supermarkets', {'name': name});

  Future<int?> selectedSupermarketId() async {
    final rows = await _db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [_selectedKey],
    );
    if (rows.isEmpty) return null;
    return int.tryParse(rows.first['value'] as String? ?? '');
  }

  Future<void> setSelectedSupermarket(int id) async {
    await _db.insert('settings', {
      'key': _selectedKey,
      'value': '$id',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Todos los productos con su mapa de precios.
  Future<List<Product>> products() async {
    final rows = await _db.query('products', orderBy: 'name COLLATE NOCASE');
    final prices = await _db.query('product_prices');
    final byProduct = <int, Map<int, double>>{};
    for (final p in prices) {
      byProduct.putIfAbsent(
        p['product_id'] as int,
        () => {},
      )[p['supermarket_id'] as int] = (p['price'] as num)
          .toDouble();
    }
    return rows.map((r) {
      final base = Product.fromMap(r);
      return base.copyWith(prices: byProduct[base.id] ?? const {});
    }).toList();
  }

  Future<Product?> findProductByName(String name) async {
    final rows = await _db.query(
      'products',
      where: 'name = ? COLLATE NOCASE',
      whereArgs: [name.trim()],
    );
    if (rows.isEmpty) return null;
    final all = await products();
    final id = rows.first['id'] as int;
    return all.firstWhere((p) => p.id == id);
  }

  Future<int> insertProduct(String name, {String? note}) =>
      _db.insert('products', {'name': name.trim(), 'note': note});

  Future<void> setPrice(int productId, int supermarketId, double? price) async {
    if (price == null) {
      await _db.delete(
        'product_prices',
        where: 'product_id = ? AND supermarket_id = ?',
        whereArgs: [productId, supermarketId],
      );
    } else {
      await _db.insert('product_prices', {
        'product_id': productId,
        'supermarket_id': supermarketId,
        'price': price,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<CartItem>> cart() async {
    final rows = await _db.query(
      'cart_items',
      orderBy: 'added_at DESC, id DESC',
    );
    final allProducts = {for (final p in await products()) p.id!: p};
    return rows
        .map((r) {
          final product = allProducts[r['product_id'] as int];
          if (product == null) return null;
          return CartItem(
            id: r['id'] as int,
            product: product,
            quantity: r['quantity'] as int,
            checked: (r['checked'] as int) == 1,
          );
        })
        .whereType<CartItem>()
        .toList();
  }

  Future<int> addToCart(int productId, {int quantity = 1}) async {
    final existing = await _db.query(
      'cart_items',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
    if (existing.isNotEmpty) {
      final id = existing.first['id'] as int;
      await _db.update(
        'cart_items',
        {
          'quantity': (existing.first['quantity'] as int) + quantity,
          'checked': 0,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      return id;
    }
    return _db.insert('cart_items', {
      'product_id': productId,
      'quantity': quantity,
      'checked': 0,
      'added_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateCartItem(CartItem item) async {
    await _db.update(
      'cart_items',
      {'quantity': item.quantity, 'checked': item.checked ? 1 : 0},
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> removeCartItem(int id) async {
    await _db.delete('cart_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearChecked() => _db.delete('cart_items', where: 'checked = 1');
}
