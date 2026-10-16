import 'package:flutter/foundation.dart';

import '../models/grocery.dart';
import '../repositories/grocery_repository.dart';

/// Comparación de un ítem respecto a otro supermercado.
class ItemComparison {
  const ItemComparison({required this.supermarket, required this.difference});

  /// Supermercado con el que se compara (el más caro para resaltar ahorro,
  /// o el más barato si el seleccionado no es el mejor).
  final Supermarket supermarket;

  /// Positivo = ahorras esa cantidad en el seleccionado frente a [supermarket].
  /// Negativo = el seleccionado es más caro.
  final double difference;
}

class GroceryProvider extends ChangeNotifier {
  GroceryProvider({GroceryRepository? repo})
    : _repo = repo ?? GroceryRepository();

  final GroceryRepository _repo;

  List<Supermarket> _supers = [];
  List<Product> _products = [];
  List<CartItem> _cart = [];
  int? _selectedId;
  bool _loaded = false;

  bool get loaded => _loaded;
  List<Supermarket> get supermarkets => _supers;
  List<Product> get products => _products;
  List<CartItem> get cart => _cart;
  int? get selectedId => _selectedId;

  Supermarket? get selected => _supers.cast<Supermarket?>().firstWhere(
    (s) => s!.id == _selectedId,
    orElse: () => null,
  );

  int get pendingCount => _cart.where((i) => !i.checked).length;

  Future<void> load() async {
    _supers = await _repo.supermarkets();
    _products = await _repo.products();
    _cart = await _repo.cart();
    _selectedId =
        await _repo.selectedSupermarketId() ?? _supers.firstOrNull?.id;
    _loaded = true;
    notifyListeners();
  }

  Future<void> selectSupermarket(int id) async {
    _selectedId = id;
    await _repo.setSelectedSupermarket(id);
    notifyListeners();
  }

  // ---------- Cálculos ----------

  /// Presupuesto de la cesta en cada supermercado, ordenado de barato a caro.
  /// Los supermercados con cobertura incompleta van al final.
  List<BasketQuote> get quotes {
    final items = _cart.where((i) => !i.checked).toList();
    final list = _supers.map((s) {
      double total = 0;
      var covered = 0;
      for (final item in items) {
        final t = item.totalAt(s.id!);
        if (t != null) {
          total += t;
          covered++;
        }
      }
      return BasketQuote(
        supermarket: s,
        total: total,
        coveredItems: covered,
        totalItems: items.length,
      );
    }).toList();
    list.sort((a, b) {
      if (a.isComplete != b.isComplete) return a.isComplete ? -1 : 1;
      if (a.coveredItems != b.coveredItems) {
        return b.coveredItems.compareTo(a.coveredItems);
      }
      return a.total.compareTo(b.total);
    });
    return list;
  }

  BasketQuote? get selectedQuote => _selectedId == null
      ? null
      : quotes.cast<BasketQuote?>().firstWhere(
          (q) => q!.supermarket.id == _selectedId,
          orElse: () => null,
        );

  /// Ahorro de la cesta en el supermercado seleccionado frente al más caro
  /// con la misma cobertura. Null si no hay con qué comparar.
  ({Supermarket other, double saving, double pct})? get basketSaving {
    final sel = selectedQuote;
    if (sel == null || sel.coveredItems == 0) return null;
    final comparable = quotes.where(
      (q) =>
          q.supermarket.id != sel.supermarket.id &&
          q.coveredItems == sel.coveredItems,
    );
    if (comparable.isEmpty) return null;
    final worst = comparable.reduce((a, b) => a.total >= b.total ? a : b);
    final saving = worst.total - sel.total;
    final pct = worst.total == 0 ? 0.0 : saving / worst.total * 100;
    return (other: worst.supermarket, saving: saving, pct: pct);
  }

  /// Comparación por unidad de un producto frente al resto de supermercados.
  ItemComparison? compare(Product p) {
    final sel = _selectedId;
    if (sel == null) return null;
    final mine = p.priceAt(sel);
    if (mine == null) return null;
    Supermarket? best;
    double bestDiff = 0;
    for (final s in _supers) {
      if (s.id == sel) continue;
      final other = p.priceAt(s.id!);
      if (other == null) continue;
      final diff = other - mine;
      if (best == null || diff.abs() > bestDiff.abs()) {
        best = s;
        bestDiff = diff;
      }
    }
    if (best == null) return null;
    return ItemComparison(supermarket: best, difference: bestDiff);
  }

  /// Supermercado donde un producto sin precio en el seleccionado sí existe.
  Supermarket? alternativeFor(Product p) {
    for (final s in _supers) {
      if (s.id != _selectedId && p.priceAt(s.id!) != null) return s;
    }
    return null;
  }

  // ---------- Mutaciones ----------

  /// Añade por nombre: reutiliza el producto si existe, si no lo crea.
  /// Devuelve el producto para que la UI ofrezca completar precios.
  Future<Product> quickAdd(String name) async {
    final existing = await _repo.findProductByName(name);
    final product =
        existing ??
        Product(id: await _repo.insertProduct(name), name: name.trim());
    await _repo.addToCart(product.id!);
    await load();
    return _products.firstWhere((p) => p.id == product.id);
  }

  Future<void> addExistingProduct(Product p) async {
    await _repo.addToCart(p.id!);
    await load();
  }

  Future<void> toggleChecked(CartItem item) async {
    await _repo.updateCartItem(item.copyWith(checked: !item.checked));
    await load();
  }

  Future<void> setQuantity(CartItem item, int qty) async {
    if (qty <= 0) {
      await _repo.removeCartItem(item.id!);
    } else {
      await _repo.updateCartItem(item.copyWith(quantity: qty));
    }
    await load();
  }

  Future<void> removeItem(CartItem item) async {
    await _repo.removeCartItem(item.id!);
    await load();
  }

  Future<int> clearChecked() async {
    final n = await _repo.clearChecked();
    await load();
    return n;
  }

  Future<void> savePrices(Product p, Map<int, double?> prices) async {
    for (final e in prices.entries) {
      await _repo.setPrice(p.id!, e.key, e.value);
    }
    await load();
  }

  Future<void> addSupermarket(String name) async {
    await _repo.addSupermarket(name);
    await load();
  }
}
